abstract class PrintingService {
  Future<bool> isAvailable();
  Future<bool> printInvoice(Map<String, dynamic> orderData);
  Future<List<String>> getAvailablePrinters();
}

class NoOpPrintingService implements PrintingService {
  @override
  Future<bool> isAvailable() async {
    // Printing hardware feature deactivated for v1
    return false;
  }

  @override
  Future<bool> printInvoice(Map<String, dynamic> orderData) async {
    // No-Op implementation for v1: digital invoices are shared via PDF/WhatsApp instead
    return true;
  }

  @override
  Future<List<String>> getAvailablePrinters() async {
    return [];
  }
}
