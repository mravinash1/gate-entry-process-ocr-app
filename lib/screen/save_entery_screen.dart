import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SavedEntriesScreen extends StatefulWidget {
  const SavedEntriesScreen({super.key, required this.savedEntries});

  final List<Map<String, dynamic>> savedEntries;

  @override
  State<SavedEntriesScreen> createState() => _SavedEntriesScreenState();
}

class _SavedEntriesScreenState extends State<SavedEntriesScreen> {
  late Box ocrBox;
  List<Map<String, dynamic>> _savedEntries = [];
  List<dynamic> _keys = [];

  @override
  void initState() {
    super.initState();
    ocrBox = Hive.box('ocr_entries');
    _loadSavedEntries();
  }

  void _loadSavedEntries() {
    try {
      final entries = ocrBox.values.map((e) {
        if (e is Map) {
          return e.cast<String, dynamic>();
        }
        return <String, dynamic>{};
      }).toList();
      
      final keys = ocrBox.keys.toList();

      setState(() {
        _savedEntries = entries.where((entry) => entry.isNotEmpty).toList();
        _keys = keys;
      });
    } catch (e) {
      print("Error loading entries: $e");
      setState(() {
        _savedEntries = [];
        _keys = [];
      });
    }
  }

  void _deleteEntry(int index) {
    if (index < 0 || index >= _keys.length) {
      print("Invalid index: $index");
      return;
    }

    ocrBox.delete(_keys[index]);
    _loadSavedEntries();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Entry deleted ")));
  }

  void _editEntry(int index) {
    if (index < 0 || index >= _savedEntries.length) return;

    final entry = _savedEntries[index];
    final key = _keys[index];

    final plantCtrl = TextEditingController(text: entry["planNo"]?.toString() ?? '');
    final gateCtrl = TextEditingController(text: entry["gateNo"]?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Entry"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: plantCtrl,
              decoration: const InputDecoration(labelText: "Plant No"),
            ),
            TextField(
              controller: gateCtrl,
              decoration: const InputDecoration(labelText: "Gate No"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final updatedEntry = Map<String, dynamic>.from(entry);
              updatedEntry["planNo"] = plantCtrl.text;
              updatedEntry["gateNo"] = gateCtrl.text;

              ocrBox.put(key, updatedEntry);
              _loadSavedEntries();
              Navigator.pop(context);

              ScaffoldMessenger.of(context)
             .showSnackBar(const SnackBar(content: Text("Entry updated ✅")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Saved Invoices"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _savedEntries.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildHeaderStats(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _savedEntries[index];
                      return _buildInvoiceCard(entry, index, context);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "No Saved Invoices",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Scan invoices to see them here",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(_savedEntries.length.toString(), "Total"),
          _buildStatItem(
            _savedEntries
                .where((entry) => entry["baseType"] == "PO ")
                .length
                .toString(),
            "PO",
          ),
          _buildStatItem(
            _savedEntries
                .where((entry) => entry["baseType"] == "Non PO")
                .length
                .toString(),
            "Non PO",
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> entry, int index, BuildContext context) {
    // Clean the vendor name for display
    String displayVendorName = _cleanVendorNameForDisplay(entry["vendorName"]?.toString() ?? "MYPCKART");
    
    // Get line items - safely handle type conversion
    List<dynamic> lineItems = [];
    try {
      if (entry["lineItems"] is List) {
        lineItems = (entry["lineItems"] as List).map((item) {
          if (item is Map) {
            return item.cast<String, dynamic>();
          }
          return <String, dynamic>{};
        }).toList();
      }
    } catch (e) {
      print("Error parsing line items: $e");
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayVendorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBaseTypeColor(entry["baseType"]?.toString()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry["baseType"]?.toString() ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              "Gate Entry No : ${entry["gateEntryNumber"]?.toString() ?? ''}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              "Vendor Code: ${entry["vendorCode"]?.toString() ?? ''}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              "P.O. No: ${entry["poNo"]?.toString() ?? ''}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              "GSTIN: ${entry["gstinNo"]?.toString() ?? ''}",
              style: TextStyle(color: Colors.grey[600]),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Gate No: ${entry["gateNo"]?.toString() ?? ''}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  "Plant No: ${entry["planNo"]?.toString() ?? ''}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            

             Text(
              "Vendor Code: ${entry["vendorCode"]?.toString() ?? ''}",
              style: TextStyle(color: Colors.grey[600]),
            ),

            Text("Line Items  :  ${lineItems.length}",style: TextStyle(color: Colors.grey[600]),),
            Text("Remarks  :  ${entry["remarks"]?.toString() ?? 'Not Available'
            }",style: TextStyle(color: Colors.grey[600],fontSize: 13),),

            
            // Line Items Summary
            // if (lineItems.isNotEmpty) ...[
            //   const SizedBox(height: 8),
            //   Text(
            //     "Items (${lineItems.length}):",
            //     style: TextStyle(
            //       fontSize: 14,
            //       fontWeight: FontWeight.w600,
            //       color: Colors.grey[700],
            //     ),
            //   ),
            //   const SizedBox(height: 4),
            //   ...lineItems.take(2).map((item) => _buildLineItemSummary(item)),
            //   if (lineItems.length > 2) ...[
            //     Text(
            //       "+ ${lineItems.length - 2} more items...",
            //       style: TextStyle(
            //         fontSize: 12,
            //         color: Colors.grey[600],
            //         fontStyle: FontStyle.italic,
            //       ),
            //     ),
            //   ],
            // ],




            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  "Invoice Date: ${entry["invoiceDate"]?.toString() ?? ''}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                const Spacer(),
                TextButton(
                  onPressed: () => _showDetailsDialog(entry, context),
                  child: const Text(
                    "View Details",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _editEntry(index),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                ),
                IconButton(
                  onPressed: () => _deleteEntry(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Line Item Summary Widget
  Widget _buildLineItemSummary(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item["description"]?.toString() ?? "Item",
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Qty: ${item["quantity"]?.toString() ?? "1"}",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Text(
            "₹${item["amount"]?.toString() ?? "0.00"}",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method to clean vendor name for display
  String _cleanVendorNameForDisplay(String vendorName) {
    if (vendorName.isEmpty) return "MYPCKART";
    
    // Remove common OCR artifacts and "vendor code" text
    String cleaned = vendorName
        .replaceAll(RegExp(r'vendor\s*code', caseSensitive: false), '')
        .replaceAll(RegExp(r'vender\s*code', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // If after cleaning it's empty, return default
    return cleaned.isEmpty ? "MYPCKART" : cleaned;
  }

  Color _getBaseTypeColor(String? baseType) {
    switch (baseType) {
      case "PO ":
        return Colors.green;
      case "Non PO":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showDetailsDialog(Map<String, dynamic> entry, BuildContext context) {
    // Clean vendor name for display
    String displayVendorName = _cleanVendorNameForDisplay(entry["vendorName"]?.toString() ?? 'MYPCKART');
    
    // Get line items - safely handle type conversion
    List<dynamic> lineItems = [];
    try {
      if (entry["lineItems"] is List) {
        lineItems = (entry["lineItems"] as List).map((item) {
          if (item is Map) {
            return item.cast<String, dynamic>();
          }
          return <String, dynamic>{};
        }).toList();
      }
    } catch (e) {
      print("Error parsing line items in dialog: $e");
    }
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  "Invoice Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow("Vendor Name", displayVendorName),
              _buildDetailRow("Vendor Code", entry["vendorCode"]?.toString() ?? ''),
              _buildDetailRow("Invoice No", entry["invoiceNo"]?.toString() ?? ''),
              _buildDetailRow("Address", entry["address"]?.toString() ?? ''),
              _buildDetailRow("P.O. Date", entry["poDate"]?.toString() ?? ''),
              _buildDetailRow("Invoice Date", entry["invoiceDate"]?.toString() ?? ''),
              _buildDetailRow("GSTIN No", entry["gstinNo"]?.toString() ?? ''),
              _buildDetailRow("P.O. No", entry["poNo"]?.toString() ?? ''),
              _buildDetailRow("PAN No", entry["panNo"]?.toString() ?? ''),
              _buildDetailRow("Plan No", entry["planNo"]?.toString() ?? ''),
              _buildDetailRow("Gate No", entry["gateNo"]?.toString() ?? ''),
              _buildDetailRow("Remarks", entry["remarks"]?.toString() ?? ''),
              _buildDetailRow("Base Type", entry["baseType"]?.toString() ?? ''),
              _buildDetailRow("Taxable Amount", entry["taxableAmount"]?.toString() ?? ''),
              _buildDetailRow("Grand Total", entry["grandTotal"]?.toString() ?? ''),

              // Line Items Section
              if (lineItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                 Text(
                  "Line Items: ${lineItems.length}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...lineItems.map((item) => _buildLineItemDetail(item)),
              ],

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Line Item Detail Widget for Dialog
  Widget _buildLineItemDetail(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item["description"]?.toString() ?? "Item",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildItemDetail("S.No", item["sno"]?.toString() ?? ""),
              _buildItemDetail("HSN", item["hsnCode"]?.toString() ?? ""),
              _buildItemDetail("Qty", item["quantity"]?.toString() ?? ""),
            ],
          ),
          Row(
            children: [
              _buildItemDetail("Rate", "₹${item["rate"]?.toString() ?? "0.00"}"),
              _buildItemDetail("Amount", "₹${item["amount"]?.toString() ?? "0.00"}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Expanded(
      child: Text(
        "$label: $value",
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? "Not available" : value),
          ),
        ],
      ),
    );
  }
}



