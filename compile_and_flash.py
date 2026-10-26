import asyncio
import json
import re
import subprocess
import sys
from pathlib import Path
import requests
import wsproto
import socket

ESPHOME_HOST = "10.0.0.50"
ESPHOME_PORT = 6052
CONFIG_NAME = "esp32-cc1101-rf-bridge.yaml"
WORK_DIR = Path(r"C:\Users\kamyar\esp32-cc1101-rf-bridge")
YAML_PATH = WORK_DIR / CONFIG_NAME
BIN_PATH = WORK_DIR / "esp32-rf433-bridge-factory.bin"
ANSI_RE = re.compile(r"\x1b\[[0-9;]*[a-zA-Z]")

def upload_config():
    print(f"[1/4] Uploading {CONFIG_NAME} to http://{ESPHOME_HOST}:{ESPHOME_PORT}...")
    content = YAML_PATH.read_text(encoding="utf-8")
    r = requests.post(
        f"http://{ESPHOME_HOST}:{ESPHOME_PORT}/edit",
        params={"configuration": CONFIG_NAME},
        data=content.encode("utf-8"),
        headers={"Content-Type": "text/plain; charset=utf-8"},
        timeout=10,
    )
    r.raise_for_status()
    print("      Upload OK.")

def compile_remote():
    print(f"[2/4] Compiling {CONFIG_NAME} on ESPHome server ({ESPHOME_HOST}:{ESPHOME_PORT})...")
    sock = socket.create_connection((ESPHOME_HOST, ESPHOME_PORT), timeout=600)
    ws = wsproto.WSConnection(wsproto.ConnectionType.CLIENT)
    sock.sendall(ws.send(wsproto.events.Request(host=f"{ESPHOME_HOST}:{ESPHOME_PORT}", target="/compile")))

    spawned = False
    exit_code = None

    while exit_code is None:
        data = sock.recv(65536)
        if not data:
            break
        ws.receive_data(data)
        for event in ws.events():
            if isinstance(event, wsproto.events.AcceptConnection):
                if not spawned:
                    msg = json.dumps({
                        "type": "spawn",
                        "configuration": CONFIG_NAME,
                        "port": "OTA",
                        "only_generate": False,
                    })
                    sock.sendall(ws.send(wsproto.events.Message(data=msg)))
                    spawned = True
            elif isinstance(event, wsproto.events.TextMessage):
                payload = json.loads(event.data)
                ev = payload.get("event")
                if ev == "line":
                    line = ANSI_RE.sub("", payload.get("data", "")).rstrip()
                    if line:
                        print("      " + line, flush=True)
                elif ev == "exit":
                    exit_code = payload.get("code", -1)
                    break
            elif isinstance(event, wsproto.events.Ping):
                sock.sendall(ws.send(event.response()))
            elif isinstance(event, wsproto.events.CloseConnection):
                break

    sock.close()
    if exit_code != 0:
        raise RuntimeError(f"Remote compile failed with exit code {exit_code}")
    print("      Compile succeeded!")

def download_factory_bin():
    print("[3/4] Downloading factory firmware binary...")
    for dl_type in ("firmware.factory.bin", "factory.bin"):
        r = requests.get(
            f"http://{ESPHOME_HOST}:{ESPHOME_PORT}/download.bin",
            params={"configuration": CONFIG_NAME, "file": dl_type},
            timeout=60,
        )
        if r.status_code == 200 and len(r.content) > 100000:
            BIN_PATH.write_bytes(r.content)
            print(f"      Downloaded {len(r.content):,} bytes (file={dl_type}) -> {BIN_PATH}")
            return
    raise RuntimeError(f"Failed to download binary: status={r.status_code}")

def flash_com3():
    print("[4/4] Flashing firmware to ESP32 on COM3 at 0x0...")
    cmd = [
        sys.executable, "-m", "esptool",
        "--chip", "esp32",
        "--port", "COM3",
        "--baud", "460800",
        "write-flash", "0x0", str(BIN_PATH),
    ]
    subprocess.run(cmd, check=True)
    print("      Flash complete!")

if __name__ == "__main__":
    upload_config()
    compile_remote()
    download_factory_bin()
    flash_com3()
