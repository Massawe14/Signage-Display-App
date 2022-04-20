import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BlueToothConnection extends StatefulWidget {
 BlueToothConnection({Key? key, required this.title}) : super(key: key);
 
 final String title;
 final FlutterBlue flutterBlue = FlutterBlue.instance;

 final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
 
 @override
 _BlueToothConnection createState() => _BlueToothConnection();
}
 
class _BlueToothConnection extends State<BlueToothConnection> {

  _addDeviceTolist(final BluetoothDevice device) {
   if (!widget.devicesList.contains(device)) {
     setState(() {
       widget.devicesList.add(device);
     });
   }
 }

 @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
   List<Container> containers = <Container>[];
   for (BluetoothDevice device in widget.devicesList) {
     containers.add(
       // ignore: sized_box_for_whitespace
       Container(
         height: 50,
         child: Row(
           children: <Widget>[
             Expanded(
               child: Column(
                 children: <Widget>[
                   Text(device.name == '' ? '(unknown device)' : device.name),
                   Text(device.id.toString()),
                 ],
               ),
             ),
             TextButton(
              //  color: Colors.blue,
               child: const Text(
                 'Connect',
                 style: TextStyle(color: Colors.white),
               ),
               onPressed: () {
                 setState(() async{
                    widget.flutterBlue.stopScan();
                    try {
                      await device.connect();
                    } catch (e) {
                      if (e != 'already_connected') {
                        rethrow;
                      }
                    }
                  });
               },
             ),
           ],
         ),
       ),
     );
   }
 
   return ListView(
     padding: const EdgeInsets.all(8),
     children: <Widget>[
       ...containers,
     ],
   );
 }
  
 @override
 Widget build(BuildContext context) => Scaffold(
       appBar: AppBar(
         title: Text(widget.title),
       ),
       body: _buildListViewOfDevices(),
     );
}