import 'package:flutter/material.dart';

/// Priority levels used across tasks, emails and alerts.
enum Priority { critical, high, medium, low }

extension PriorityX on Priority {
  String get label {
    switch (this) {
      case Priority.critical:
        return 'Critical';
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case Priority.critical:
        return const Color(0xFFE5484D);
      case Priority.high:
        return const Color(0xFFF5A524);
      case Priority.medium:
        return const Color(0xFF3E9EFF);
      case Priority.low:
        return const Color(0xFF7C8598);
    }
  }

  /// Higher weight sorts first.
  int get weight {
    switch (this) {
      case Priority.critical:
        return 3;
      case Priority.high:
        return 2;
      case Priority.medium:
        return 1;
      case Priority.low:
        return 0;
    }
  }
}

extension PriorityWire on Priority {
  String get wire => name; // critical/high/medium/low
  static Priority fromWire(String? v) => Priority.values.firstWhere(
        (e) => e.name == v,
        orElse: () => Priority.medium,
      );
}

enum TaskStatus { open, inProgress, blocked, done, cancelled }

extension TaskStatusWire on TaskStatus {
  String get wire {
    switch (this) {
      case TaskStatus.open:
        return 'open';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.blocked:
        return 'blocked';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  static TaskStatus fromWire(String? v) {
    switch (v) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'blocked':
        return TaskStatus.blocked;
      case 'done':
        return TaskStatus.done;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.open;
    }
  }
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.open:
        return 'To do';
      case TaskStatus.inProgress:
        return 'In progress';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.done:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.open:
        return const Color(0xFF7C8598);
      case TaskStatus.inProgress:
        return const Color(0xFF3E9EFF);
      case TaskStatus.blocked:
        return const Color(0xFFE5484D);
      case TaskStatus.done:
        return const Color(0xFF30A46C);
      case TaskStatus.cancelled:
        return const Color(0xFF7C8598);
    }
  }
}

enum EmailKind {
  customerInquiry,
  supplierQuote,
  purchaseOrder,
  contract,
  invoice,
  meetingRequest,
  general,
}

extension EmailKindWire on EmailKind {
  String get wire {
    switch (this) {
      case EmailKind.customerInquiry:
        return 'customer_inquiry';
      case EmailKind.supplierQuote:
        return 'supplier_quote';
      case EmailKind.purchaseOrder:
        return 'purchase_order';
      case EmailKind.contract:
        return 'contract';
      case EmailKind.invoice:
        return 'invoice';
      case EmailKind.meetingRequest:
        return 'meeting_request';
      case EmailKind.general:
        return 'general';
    }
  }

  static EmailKind fromWire(String? v) {
    switch (v) {
      case 'customer_inquiry':
        return EmailKind.customerInquiry;
      case 'supplier_quote':
        return EmailKind.supplierQuote;
      case 'purchase_order':
        return EmailKind.purchaseOrder;
      case 'contract':
        return EmailKind.contract;
      case 'invoice':
        return EmailKind.invoice;
      case 'meeting_request':
        return EmailKind.meetingRequest;
      default:
        return EmailKind.general;
    }
  }
}

extension EmailKindX on EmailKind {
  String get label {
    switch (this) {
      case EmailKind.customerInquiry:
        return 'Customer inquiry';
      case EmailKind.supplierQuote:
        return 'Supplier quotation';
      case EmailKind.purchaseOrder:
        return 'Purchase order';
      case EmailKind.contract:
        return 'Contract';
      case EmailKind.invoice:
        return 'Invoice';
      case EmailKind.meetingRequest:
        return 'Meeting request';
      case EmailKind.general:
        return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case EmailKind.customerInquiry:
        return Icons.person_search_outlined;
      case EmailKind.supplierQuote:
        return Icons.request_quote_outlined;
      case EmailKind.purchaseOrder:
        return Icons.shopping_bag_outlined;
      case EmailKind.contract:
        return Icons.handshake_outlined;
      case EmailKind.invoice:
        return Icons.receipt_long_outlined;
      case EmailKind.meetingRequest:
        return Icons.event_outlined;
      case EmailKind.general:
        return Icons.mail_outline;
    }
  }
}

enum AlertKind { risk, opportunity, attention }

enum TimelineKind {
  contract,
  purchase,
  newCustomer,
  decision,
  milestone,
}

extension TimelineKindWire on TimelineKind {
  String get wire {
    switch (this) {
      case TimelineKind.contract:
        return 'contract';
      case TimelineKind.purchase:
        return 'purchase';
      case TimelineKind.newCustomer:
        return 'new_customer';
      case TimelineKind.decision:
        return 'decision';
      case TimelineKind.milestone:
        return 'milestone';
    }
  }

  static TimelineKind fromWire(String? v) {
    switch (v) {
      case 'contract':
        return TimelineKind.contract;
      case 'purchase':
        return TimelineKind.purchase;
      case 'new_customer':
        return TimelineKind.newCustomer;
      case 'decision':
        return TimelineKind.decision;
      default:
        return TimelineKind.milestone;
    }
  }
}

extension TimelineKindX on TimelineKind {
  String get label {
    switch (this) {
      case TimelineKind.contract:
        return 'Contract';
      case TimelineKind.purchase:
        return 'Major purchase';
      case TimelineKind.newCustomer:
        return 'New customer';
      case TimelineKind.decision:
        return 'Decision';
      case TimelineKind.milestone:
        return 'Milestone';
    }
  }

  IconData get icon {
    switch (this) {
      case TimelineKind.contract:
        return Icons.description_outlined;
      case TimelineKind.purchase:
        return Icons.local_shipping_outlined;
      case TimelineKind.newCustomer:
        return Icons.group_add_outlined;
      case TimelineKind.decision:
        return Icons.gavel_outlined;
      case TimelineKind.milestone:
        return Icons.flag_outlined;
    }
  }
}
