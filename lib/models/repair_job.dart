class RepairJob {
  final int? id;
  final String? jobNo;
  final String customerName;
  final String? customerPhone;
  final String deviceModel;
  final String issueDescription;
  final double estimatedCost;
  final String status; // Received, In Progress, Ready, Delivered, Cancelled
  final int createdAt;

  RepairJob({
    this.id,
    String? jobNo,
    required this.customerName,
    this.customerPhone,
    required this.deviceModel,
    required this.issueDescription,
    required this.estimatedCost,
    this.status = 'Received',
    required this.createdAt,
  }) : jobNo = jobNo ?? 'REP_${DateTime.now().millisecondsSinceEpoch % 1000000}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      id: map['id'] as int?,
      jobNo: map['job_no']?.toString() ?? map['jobNo']?.toString(),
      customerName: map['customer_name']?.toString() ?? map['customerName']?.toString() ?? '',
      customerPhone: map['customer_phone']?.toString() ?? map['customerPhone']?.toString(),
      deviceModel: map['device_model']?.toString() ?? map['deviceModel']?.toString() ?? '',
      issueDescription: map['issue_description']?.toString() ?? map['issueDescription']?.toString() ?? '',
      estimatedCost: (map['estimated_cost'] as num?)?.toDouble() ?? (map['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'Received',
      createdAt: (map['created_at'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
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
