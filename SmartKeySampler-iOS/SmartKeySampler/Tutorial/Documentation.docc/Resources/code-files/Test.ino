#include <NimBLEDevice.h>
#include <ESP32Servo.h>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define COMPLETE_LOCAL_NAME "ESP-TEST-DEVICE"
#define SERVICE_UUID "3c3996e0-4d2c-11ed-bdc3-0242ac120002"
#define CHARACTERISTIC_UUID "3c399a64-4d2c-11ed-bdc3-0242ac120002"
#define CHARACTERISTIC_UUID_NOTIFY "3c399c44-4d2c-11ed-bdc3-0242ac120002"
// Servo
Servo servo;
static int LED_PIN = 13;
// Characteristic
NimBLECharacteristic *pNotifyCharacteristic;
// NimBLEServer
NimBLEServer *pServer = NULL;

bool deviceConnected = false;
bool oldDeviceConnected = false;
String stateValue = "0";
uint8_t data_buff[2]; // データ通知用バッファ

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(NimBLEServer * pServer) {
    // BLE接続があった場合にスリープモードを解除する
  }
};

class ServerCallbacks : public NimBLEServerCallbacks
{
  //接続時
  void onConnect(NimBLEServer *pServer)
  {
    Serial.println("Client connected");
    deviceConnected = true;
    Serial.println("スリープモード解除");
   esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_TIMER);
  };
  //切断時
  void onDisconnect(NimBLEServer *pServer)
  {
    Serial.println("Client disconnected - start advertising");
    deviceConnected = false;
    NimBLEDevice::startAdvertising();
    Serial.println("スリープモードに入ります");
    esp_deep_sleep_start();
  };
  void onMTUChange(uint16_t MTU, ble_gap_conn_desc *desc)
  {
    Serial.printf("MTU updated: %u for connection ID: %u\n", MTU, desc->conn_handle);
  };
  // Passのリクエスト
  uint32_t onPassKeyRequest()
  {
    Serial.println("Server Passkey Request");
    return 123456;
  };
  //確認
  bool onConfirmPIN(uint32_t pass_key)
  {
    Serial.print("The passkey YES/NO number: ");
    Serial.println(pass_key);
    return true;
  };
  //認証完了時の処理
  void onAuthenticationComplete(ble_gap_conn_desc *desc)
  {
    if (!desc->sec_state.encrypted)
    {
      NimBLEDevice::getServer()->disconnect(desc->conn_handle);
      Serial.println("Encrypt connection failed - disconnecting client");
      return;
    }
    Serial.println("Starting BLE work!");
  };
};

// Bluetooth LE Recive
class BLECallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    std::string value = pCharacteristic->getValue();

    if (value.length() > 0)
    {
      String keyLockedState = value.c_str();
      Serial.println(keyLockedState);
      if (keyLockedState == "OFF")
      {
        stateValue = keyLockedState;
        pNotifyCharacteristic->setValue(stateValue);
        pNotifyCharacteristic->notify();
        servo.write(0);
      }
      else if (keyLockedState == "ON")
      {
        stateValue = keyLockedState;
        pNotifyCharacteristic->setValue(stateValue);
        pNotifyCharacteristic->notify();
        servo.write(130);
      }
    }
  }
};

// Bluetooth LE loop
void loopBLE()
{
  // disconnecting
  if (!deviceConnected && oldDeviceConnected)
  {
    delay(500);                  // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("restartAdvertising");
    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected)
  {
    // do stuff here on connecting
    oldDeviceConnected = deviceConnected;
  }
}

void setup()
{
  Serial.begin(115200);
  Serial.println("Starting NimBLE Server");
  BLEDevice::init(COMPLETE_LOCAL_NAME);
  // CompleteLocalNameのセット
  NimBLEDevice::init(COMPLETE_LOCAL_NAME);
  // TxPowerのセット
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);

  //セキュリティセッティング
  // bonding,MITM,sc
  //セキュリティ無し
  // NimBLEDevice::setSecurityAuth(false, false, false);
  //ボンディング有り
  // NimBLEDevice::setSecurityAuth(true, false, false);
  // ボンディング有り、mitm有り
  // NimBLEDevice::setSecurityAuth(true, true, false);
  //ボンディング有り、mitm有り,sc有り
   NimBLEDevice::setSecurityAuth(true, true, true);
  // PassKeyのセット
   NimBLEDevice::setSecurityPasskey(123456);
  //パラメータでディスプレイ有りに設定
   NimBLEDevice::setSecurityIOCap(BLE_HS_IO_DISPLAY_ONLY);
  //パラメータでInOut無しに設定
   NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);
  pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  NimBLEService *pService = pServer->createService(SERVICE_UUID);

  // RxCharacteristic
  NimBLECharacteristic *pRxCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID, NIMBLE_PROPERTY::WRITE);
  // NotifyCharacteristic
  // NoSec
  // pNotifyCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_NOTIFY, NIMBLE_PROPERTY::NOTIFY);
  // Need Enc
  // pNotifyCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_NOTIFY, NIMBLE_PROPERTY::NOTIFY | NIMBLE_PROPERTY::READ_ENC);
  // Need Authen
  // pNotifyCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_NOTIFY, NIMBLE_PROPERTY::NOTIFY | NIMBLE_PROPERTY::READ_AUTHEN);
  // Need Enc Authen
  pNotifyCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_NOTIFY, NIMBLE_PROPERTY::NOTIFY | NIMBLE_PROPERTY::READ_ENC | NIMBLE_PROPERTY::READ_AUTHEN);

  // RxCharacteristicにコールバックをセット
  pRxCharacteristic->setCallbacks(new BLECallbacks());
  // Serivice開始
  pService->start();
  //アドバタイズの設定
  NimBLEAdvertising *pNimBleAdvertising = NimBLEDevice::getAdvertising();
  //アドバタイズするUUIDのセット
  pNimBleAdvertising->addServiceUUID(SERVICE_UUID);
  //アドバタイズにTxPowerセット
  pNimBleAdvertising->addTxPower();

  //アドバタイズデータ作成
  NimBLEAdvertisementData advertisementData;
  //アドバタイズにCompleteLoacaNameセット
  advertisementData.setName(COMPLETE_LOCAL_NAME);
  //アドバタイズのManufactureSpecificにデータセット
  advertisementData.setManufacturerData("NORA");
  // ScanResponseを行う
  pNimBleAdvertising->setScanResponse(true);
  // ScanResponseにアドバタイズデータセット
  pNimBleAdvertising->setScanResponseData(advertisementData);
  //アドバタイズ開始
  pNimBleAdvertising->start();
  Serial.println("first startAdvertising");

  //   // スリープモードに入る
  // esp_sleep_enable_timer_wakeup(5 * 1000000);// 60秒後に起動する
  // Serial.println("スリープモードから5秒たったので起動しました");
  // delay(5000);                          
  // // esp_sleep_enable_ext0_wakeup(GPIO_NUM_0, 1); // GPIO0の状態がHIGHになったときに起動する
  // Serial.println("スリープモードに入ります");
  // esp_deep_sleep_start();
}

void loop()
{
 // loopBLE();
}
