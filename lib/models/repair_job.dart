class RepairJob {
  final int id;
  final String jobNo;
  final String customerName;
  final String? customerPhone;
  final String deviceModel;
  final String issueDescription;
  final double estimatedCost;
  final String status; // 'received', 'in_progress', 'ready', 'delivered', 'cancelled'
  final int createdAt;

  RepairJob({
    this.id = 0,
    required this.jobNo,
    required this.customerName,
    this.customerPhone,
    required this.deviceModel,
    required this.issueDescription,
    this.estimatedCost = 0.0,
    this.status = 'received',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'job_no': jobNo,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'device_model': deviceModel,
      'issue_description': issueDescription,
      'estimated_cost': estimatedCost,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory RepairJob.fromMap(Map<String, dynamic> map) {
    return RepairJob(
      id: map['id'] ?? 0,
      jobNo: map['job_no'] ?? '',
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'],
      deviceModel: map['device_model'] ?? '',
      issueDescription: map['issue_description'] ?? '',
      estimatedCost: (map['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'received',
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  RepairJob copyWith({
    int? id,
    String? jobNo,
    String? customerName,
    String? customerPhone,
    String? deviceModel,
    String? issueDescription,
    double? estimatedCost,
    String? status,
    int? createdAt,
  }) {
    return RepairJob(
      id: id ?? this.id,
      jobNo: jobNo ?? this.jobNo,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deviceModel: deviceModel ?? this.deviceModel,
      issueDescription: issueDescription ?? this.issueDescription,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
