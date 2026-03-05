import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final dynamic order;
  const OrderTrackingScreen({super.key, required this.order});
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;

  // Prayagraj coordinates
  static const LatLng _storeLocation = LatLng(25.4358, 81.8463);
  static const LatLng _deliveryLocation = LatLng(25.4484, 81.8822);
  static const LatLng _riderLocation = LatLng(25.4420, 81.8650);

  String get _status => widget.order['status'] ?? 'pending';

  List<Map<String, dynamic>> get _steps => [
    {'label': 'Order Placed', 'icon': Icons.check_circle, 'done': true},
    {'label': 'Confirmed', 'icon': Icons.store, 'done': _status != 'pending'},
    {'label': 'Out for Delivery', 'icon': Icons.delivery_dining,
      'done': _status == 'out_for_delivery' || _status == 'delivered'},
    {'label': 'Delivered', 'icon': Icons.home, 'done': _status == 'delivered'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text('Track Order #${widget.order['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        // Map
        SizedBox(
          height: 280,
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(25.4420, 81.8650),
              zoom: 13,
            ),
            onMapCreated: (c) => _mapController = c,
            markers: {
              Marker(
                markerId: const MarkerId('store'),
                position: _storeLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Store'),
              ),
              Marker(
                markerId: const MarkerId('delivery'),
                position: _deliveryLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
                infoWindow: const InfoWindow(title: 'Delivery Location'),
              ),
              if (_status == 'out_for_delivery')
                Marker(
                  markerId: const MarkerId('rider'),
                  position: _riderLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange),
                  infoWindow: const InfoWindow(title: 'Delivery Rider'),
                ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: const [_storeLocation, _riderLocation, _deliveryLocation],
                color: Colors.green,
                width: 4,
              ),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),

        // Status Steps
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // Order Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Column(children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.local_shipping_outlined,
                          color: Colors.green.shade700),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Estimated Delivery',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('30 - 45 minutes',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 16, color: Colors.green.shade700)),
                    ]),
                  ]),
                  const SizedBox(height: 20),

                  // Progress Steps
                  ..._steps.asMap().entries.map((e) {
                    final i = e.key;
                    final step = e.value;
                    final isLast = i == _steps.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: step['done'] ? Colors.green.shade700
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(step['icon'],
                                size: 16,
                                color: step['done'] ? Colors.white
                                    : Colors.grey.shade400),
                          ),
                          if (!isLast) Container(
                            width: 2, height: 32,
                            color: step['done'] ? Colors.green.shade300
                                : Colors.grey.shade200,
                          ),
                        ]),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(step['label'],
                              style: TextStyle(
                                fontWeight: step['done']
                                    ? FontWeight.bold : FontWeight.normal,
                                color: step['done'] ? Colors.black87
                                    : Colors.grey.shade400,
                              )),
                        ),
                      ],
                    );
                  }).toList(),
                ]),
              ),

              const SizedBox(height: 16),

              // Order Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Column(children: [
                  _infoRow('Order ID', '#${widget.order['id']}'),
                  const Divider(height: 20),
                  _infoRow('Total Amount', '₹${widget.order['total_price']}'),
                  const Divider(height: 20),
                  _infoRow('Payment', 'Cash on Delivery'),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
