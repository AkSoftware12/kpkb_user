class Multistoreorder {
  List<OrderDetail>? orderDetails;

  Multistoreorder({this.orderDetails});

  Multistoreorder.fromJson(Map<String, dynamic> json) {
    if (json['order_details'] != null) {
      orderDetails = <OrderDetail>[];
      json['order_details'].forEach((v) {
        orderDetails?.add(new OrderDetail.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.orderDetails != null) {
      data['order_details'] = this.orderDetails!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }
}

class OrderDetail {
  dynamic? vendorId;
  dynamic? vendorAddress;
  dynamic? vendorName;
  dynamic? vendorPhone;
  dynamic? vendorLat;
  dynamic? vendorLng;
  List<Vendordetails>? vendordetails;

  OrderDetail({
    this.vendorId,
    this.vendorAddress,
    this.vendorName,
    this.vendorPhone,
    this.vendorLat,
    this.vendorLng,
    this.vendordetails,
  });

  OrderDetail.fromJson(Map<String, dynamic> json) {
    vendorId = json['vendor_id'];
    vendorAddress = json['vendor_address'];
    vendorName = json['vendor_name'];
    vendorPhone = json['vendor_phone'];
    vendorLat = json['vendor_lat'];
    vendorLng = json['vendor_lng'];
    if (json['vendordetails'] != null) {
      vendordetails = <Vendordetails>[];
      json['vendordetails'].forEach((v) {
        vendordetails!.add(new Vendordetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['vendor_id'] = this.vendorId;
    data['vendor_address'] = this.vendorAddress;
    data['vendor_name'] = this.vendorName;
    data['vendor_phone'] = this.vendorPhone;
    data['vendor_lat'] = this.vendorLat;
    data['vendor_lng'] = this.vendorLng;
    if (this.vendordetails != null) {
      data['vendordetails'] = this.vendordetails!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }
}

class Vendordetails {
  dynamic productName;
  dynamic price;
  dynamic unit;
  dynamic quantity;
  dynamic varientImage;
  dynamic description;
  dynamic varientId;
  dynamic storeOrderId;
  dynamic qty;
  dynamic vendorId;
  dynamic vendorName;
  dynamic lat;
  dynamic lng;
  dynamic vendorLoc;
  dynamic vendorPhone;
  dynamic totalItems;

  Vendordetails({
    this.productName,
    this.price,
    this.unit,
    this.quantity,
    this.varientImage,
    this.description,
    this.varientId,
    this.storeOrderId,
    this.qty,
    this.vendorId,
    this.vendorName,
    this.lat,
    this.lng,
    this.vendorLoc,
    this.vendorPhone,
    this.totalItems,
  });

  Vendordetails.fromJson(Map<String, dynamic> json) {
    productName = json['product_name'];
    price = json['price'];
    unit = json['unit'];
    quantity = json['quantity'];
    varientImage = json['varient_image'];
    description = json['description'];
    varientId = json['varient_id'];
    storeOrderId = json['store_order_id'];
    qty = json['qty'];
    vendorId = json['vendor_id'];
    vendorName = json['vendor_name'];
    lat = json['lat'];
    lng = json['lng'];
    vendorLoc = json['vendor_loc'];
    vendorPhone = json['vendor_phone'];
    totalItems = json['total_items'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_name'] = this.productName;
    data['price'] = this.price;
    data['unit'] = this.unit;
    data['quantity'] = this.quantity;
    data['varient_image'] = this.varientImage;
    data['description'] = this.description;
    data['varient_id'] = this.varientId;
    data['store_order_id'] = this.storeOrderId;
    data['qty'] = this.qty;
    data['vendor_id'] = this.vendorId;
    data['vendor_name'] = this.vendorName;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['vendor_loc'] = this.vendorLoc;
    data['vendor_phone'] = this.vendorPhone;
    data['total_items'] = this.totalItems;
    return data;
  }
}
