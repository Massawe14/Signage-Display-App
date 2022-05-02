import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:getwidget/getwidget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight]);
    return MaterialApp(
      title: 'LED Bluetooth Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection connection;
  int _deviceState;
  bool get isConnected => connection != null && connection.isConnected;
  List<BluetoothDevice> _devicesList = [];
  bool _isButtonUnavailable = true;
  bool _connected = false;
  BluetoothDevice _device;
  DateTime _date = DateTime.now();

  TextEditingController _datecontroller;
  TextEditingController _daysWorkedcontroller;
  TextEditingController _firstAidCasescontroller;
  TextEditingController _injuriescontroller;
  TextEditingController _lastIncidentDatecontroller;
  TextEditingController _daysWithoutAccidentcontroller;

  Future<void> _selectDate(BuildContext context) async {
    DateTime _datePicker = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      textDirection: TextDirection.ltr,
      initialDatePickerMode: DatePickerMode.day,
      selectableDayPredicate: (DateTime val) => val.weekday == 6 || val.weekday == 7 ? false : true,
    );

    if (_datePicker != null && _datePicker != _date) {
      setState(() {
        _date = _datePicker;
        print(
          _date.toString(),
        );
      });
    }
  }
  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    _deviceState = 0;
    enableBluetooth();
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState bluetoothState) {
      setState(() {
        _bluetoothState = bluetoothState;
        getPairedDevices();
      });
    });
    _datecontroller = TextEditingController();
    _daysWorkedcontroller = TextEditingController();
    _firstAidCasescontroller = TextEditingController();
    _injuriescontroller = TextEditingController();
    _lastIncidentDatecontroller = TextEditingController();
    _daysWithoutAccidentcontroller = TextEditingController();
  }

  Future<void> enableBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print('Error');
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _devicesList = devices;
    });
  }

  Future show(
      {String message, Duration duration: const Duration(seconds: 3)}) async {
    await Future.delayed(Duration(milliseconds: 100));
    // ignore: deprecated_member_use
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: duration,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('LED Bluetooth Controller'),
          centerTitle: true,
          actions: <Widget>[
            Tooltip(
                message: 'Refresh the list of bluetooth devices',
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await getPairedDevices().then((_) {
                      show(message: 'Device List Refreshed');
                    });
                  },
                )),
            Tooltip(
              message: 'Open bluetooth settings',
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                onPressed: () {
                  FlutterBluetoothSerial.instance.openSettings();
                },
              ),
            )
          ],
        ),
        body: ListView(
          children: <Widget>[
            Visibility(
              visible: _isButtonUnavailable &&
                  _bluetoothState == BluetoothState.STATE_ON,
              child: LinearProgressIndicator(
                backgroundColor: Colors.amber,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Tap to Enable Blutooth',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                  bluetoothSwitch()
                ],
              ),
            ),
            Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'Paired Devices',
                        style: TextStyle(color: Colors.black, fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Device: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          // SizedBox(
                          //   width: 8,
                          // ),
                          deviceDropDownList(),
                          // SizedBox(
                          //   width: 20,
                          // ),
                          connectionButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextFormField(
                enabled: isConnected,
                controller: _datecontroller,
                cursorColor: Colors.amber,
                readOnly: true,
                onTap: () {
                  setState(() {
                    _selectDate(context);
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Date',
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  hintText: (_date.toString()),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.amber,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GFButton(
                onPressed: (){
                  if(_connected){
                    _sendData(_datecontroller.text);
                  }
                },
                text: "SEND",
                size: GFSize.LARGE,
                blockButton: true,
                color: Colors.amber,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextFormField(
                enabled: _connected,
                controller: _daysWorkedcontroller,
                decoration: const InputDecoration(
                  labelText: 'Days worked so far',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.amber,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GFButton(
                onPressed: (){
                  if(_connected){
                    _sendData(_daysWorkedcontroller.text);
                  }
                },
                text: "SEND",
                size: GFSize.LARGE,
                blockButton: true,
                color: Colors.amber,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextFormField(
                enabled: _connected,
                controller: _firstAidCasescontroller,
                decoration: const InputDecoration(
                  labelText: 'First aid cases',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.amber,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GFButton(
                onPressed: (){
                  if(_connected){
                    _sendData(_firstAidCasescontroller.text);
                  }
                },
                text: "SEND",
                size: GFSize.LARGE,
                blockButton: true,
                color: Colors.amber,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextFormField(
                enabled: _connected,
                controller: _injuriescontroller,
                decoration: const InputDecoration(
                  labelText: 'Recordable injuries',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.amber,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GFButton(
                onPressed: (){
                  if(_connected){
                    _sendData(_injuriescontroller.text);
                  }
                },
                text: "SEND",
                size: GFSize.LARGE,
                blockButton: true,
                color: Colors.amber,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextFormField(
                enabled: _connected,
                controller: _lastIncidentDatecontroller,
                cursorColor: Colors.amber,
                readOnly: true,
                onTap: () {
                  setState(() {
                    _selectDate(context);
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Last Incident Date',
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  hintText: (_date.toString()),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.amber,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GFButton(
                onPressed: (){
                  if(_connected){
                    _sendData(_lastIncidentDatecontroller.text);
                  }
                },
                text: "SEND",
                size: GFSize.LARGE,
                blockButton: true,
                color: Colors.amber,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextFormField(
                enabled: _connected,
                controller: _daysWithoutAccidentcontroller,
                decoration: const InputDecoration(
                  labelText: 'Days without accident',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.amber,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GFButton(
                onPressed: (){
                  if(_connected){
                    _sendData(_daysWithoutAccidentcontroller.text);
                  }
                },
                text: "SEND",
                size: GFSize.LARGE,
                blockButton: true,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bluetoothSwitch() {
    return Switch(
      value: _bluetoothState.isEnabled,
      onChanged: (bool value) {
        future() async {
          if (value) {
            await FlutterBluetoothSerial.instance.requestEnable();
          } else {
            await FlutterBluetoothSerial.instance.requestDisable();
          }
          await getPairedDevices();
          _isButtonUnavailable = false;
          if (_connected) {
            _disconnect();
          }
        }
        future().then((_) {
          setState(() {});
        });
      },
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('None'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  void _connect() async {
    if (_device == null) {
      // ignore: deprecated_member_use
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('No device selected'),
      ));
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          // ignore: deprecated_member_use
          _scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text('Connected'),
          ));
          connection = _connection;
          setState(() {
            _connected = true;
          });
          connection.input.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnected locally');
            } else {
              print('Disconnected remotely');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect');
          print(error);
        });
        _deviceState = -1;
        // ignore: deprecated_member_use
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Connected'),
        ));
      }
    }
  }

  void _disconnect() async {
    await connection.close();
    // ignore: deprecated_member_use
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text('Disconnected'),
    ));
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
      });
    }
  }

  Widget connectionButton() {
    // ignore: deprecated_member_use
    return IconButton(
      icon: const Icon(
        Icons.bluetooth_searching,
        size: 35.0,
        color: Colors.amber,
      ),
      onPressed: _isButtonUnavailable
          ? null
          : _connected ? _disconnect : _connect,
    );
  }

  void turnOn() async {
    connection.output.add(utf8.encode("1" + "\r\n"));
    await connection.output.allSent;
    setState(() {
      _deviceState = 1;
    });
  }

  void turnOff() async {
    connection.output.add(utf8.encode("0" + "\r\n"));
    await connection.output.allSent;
    setState(() {
      _deviceState = -1;
    });
  }

  Widget deviceDropDownList() {
    return DropdownButton(
      items: _getDeviceItems(),
      onChanged: (value) {
        setState(() {
          _device = value;
          _isButtonUnavailable = false;
        });
      },
      value: _devicesList.isNotEmpty ? _device : null,
    );
  }

  bool isDisconnecting;
  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    super.dispose();
  }

  // Send data to the device
  void _sendData(String data) async {
    data = data.trim();
    _datecontroller.clear();
    _daysWorkedcontroller.clear();
    _firstAidCasescontroller.clear();
    _injuriescontroller.clear();
    _lastIncidentDatecontroller.clear();
    _daysWithoutAccidentcontroller.clear();

    if (data.length > 0) {
      try {
        connection.output.add(utf8.encode('$data\r\n'));
        await connection.output.allSent;
      } on PlatformException catch (e) {
        print("Error: ${e.message}");
      }
    }
  }
}
