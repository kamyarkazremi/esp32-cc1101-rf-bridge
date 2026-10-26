#pragma once

#include "esphome.h"
#include <SPI.h>
#include <ELECHOUSE_CC1101_SRC_DRV.h>

namespace cc1101_bridge {

// Pin definitions matching Section 2 Hardware & Pin Mapping
static constexpr uint8_t PIN_GDO0 = 4;
static constexpr uint8_t PIN_CSN  = 5;
static constexpr uint8_t PIN_SCK  = 18;
static constexpr uint8_t PIN_MISO = 19;
static constexpr uint8_t PIN_MOSI = 23;

static constexpr const char *TAG = "cc1101_bridge";

inline bool init_cc1101(float freq_mhz = 433.92f, float rx_bw_khz = 812.50f, int tx_pa_dbm = 10) {
  ELECHOUSE_cc1101.setSpiPin(PIN_SCK, PIN_MISO, PIN_MOSI, PIN_CSN);
  ELECHOUSE_cc1101.setGDO0(PIN_GDO0);

  if (!ELECHOUSE_cc1101.getCC1101()) {
    ESP_LOGE(TAG, "CC1101 SPI check failed! Verify wiring: SCK=%u, MISO=%u, MOSI=%u, CSN=%u, VCC=3.3V",
             PIN_SCK, PIN_MISO, PIN_MOSI, PIN_CSN);
    return false;
  }

  ELECHOUSE_cc1101.Init();
  ELECHOUSE_cc1101.setCCMode(0);          // Asynchronous Serial Mode (raw pulse train on GDO0)
  ELECHOUSE_cc1101.setModulation(2);      // 2 = ASK / OOK
  ELECHOUSE_cc1101.setMHZ(freq_mhz);      // 433.92 MHz center frequency
  ELECHOUSE_cc1101.setRxBW(rx_bw_khz);    // 812.50 kHz RX bandwidth for EV1527 crystal drift tolerance
  ELECHOUSE_cc1101.setPA(tx_pa_dbm);      // +10 dBm TX power for AC relay control
  ELECHOUSE_cc1101.SetRx();               // Default to RX mode

  // Ensure GPIO4 is in INPUT mode so ESPHome remote_receiver can read GDO0 pulse trains
  pinMode(PIN_GDO0, INPUT);

  ESP_LOGI(TAG, "CC1101 initialized: %.2f MHz, ASK/OOK, Async Mode, RxBW=%.2f kHz, Mode=RX",
           freq_mhz, rx_bw_khz);
  return true;
}

inline void enter_tx_mode() {
  ELECHOUSE_cc1101.SetTx();
  pinMode(PIN_GDO0, OUTPUT);
  delayMicroseconds(500);
}

inline void enter_rx_mode() {
  // Release GPIO4 push-pull driver back to high-impedance input before CC1101 drives GDO0 in RX mode
  pinMode(PIN_GDO0, INPUT);
  ELECHOUSE_cc1101.SetRx();
}

}  // namespace cc1101_bridge
