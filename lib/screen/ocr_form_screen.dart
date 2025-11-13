import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocrsave/repository/new_ocr_repository.dart';
import 'package:ocrsave/screen/login_screen.dart';
import 'package:ocrsave/screen/save_entery_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class OCRFormScreen extends StatefulWidget {
  const OCRFormScreen({super.key});

  @override
  State<OCRFormScreen> createState() => _OCRFormScreenState();
}

class _OCRFormScreenState extends State<OCRFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Text controllers

  final TextEditingController vendorNameCtrl = TextEditingController();
  final TextEditingController vendorCodeCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController poDateCtrl = TextEditingController();
  final TextEditingController invoiceDateCtrl = TextEditingController();
  final TextEditingController gstinNoCtrl = TextEditingController();
  final TextEditingController poNoCtrl = TextEditingController();
  final TextEditingController panNoCtrl = TextEditingController();
  final TextEditingController invoiceNoCtrl = TextEditingController();
  final TextEditingController grandTotalCtrl = TextEditingController();
  final TextEditingController taxableAmountCtrl = TextEditingController();
  final TextEditingController remarksCtrl= TextEditingController();
  final TextEditingController vehicleCtrl= TextEditingController();
  final TextEditingController drivernameCtrl= TextEditingController();



  // Line items controllers
  final List<TextEditingController> itemSnoControllers = [];
  final List<TextEditingController> itemDescriptionControllers = [];
  final List<TextEditingController> itemHsnControllers = [];
  final List<TextEditingController> itemQuantityControllers = [];
  final List<TextEditingController> itemRateControllers = [];
  final List<TextEditingController> itemAmountControllers = [];
  final List<TextEditingController> itemCgstRateControllers = [];
  final List<TextEditingController> itemCgstAmountControllers = [];
  final List<TextEditingController> itemSgstRateControllers = [];
  final List<TextEditingController> itemSgstAmountControllers = [];

  List<Map<String, dynamic>> _savedEntries = [];
  File? _imageFile;
  bool _isLoading = false;

  late Box ocrBox;

  @override
  void initState() {
    super.initState();
    ocrBox = Hive.box('ocr_entries');
    _loadSavedEntries();
    _addItemControllers(); // Start with one item
  }




String _generateGateEntryNumber() {
  final random = Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  final randomNum = random.nextInt(9000) + 1000; // Random 4-digit number
  return 'GE$timestamp$randomNum';
}
  void _addItemControllers() {
    setState(() {
      itemSnoControllers.add(TextEditingController(text: (itemSnoControllers.length + 1).toString()));
      itemDescriptionControllers.add(TextEditingController());
      itemHsnControllers.add(TextEditingController());
      itemQuantityControllers.add(TextEditingController(text: "1"));
      itemRateControllers.add(TextEditingController());
      itemAmountControllers.add(TextEditingController());
      itemCgstRateControllers.add(TextEditingController(text: "9"));
      itemCgstAmountControllers.add(TextEditingController());
      itemSgstRateControllers.add(TextEditingController(text: "9"));
      itemSgstAmountControllers.add(TextEditingController());
    });
  }

  void _removeItemControllers(int index) {
    if (itemSnoControllers.length > 1) {
      setState(() {
        itemSnoControllers.removeAt(index);
        itemDescriptionControllers.removeAt(index);
        itemHsnControllers.removeAt(index);
        itemQuantityControllers.removeAt(index);
        itemRateControllers.removeAt(index);
        itemAmountControllers.removeAt(index);
        itemCgstRateControllers.removeAt(index);
        itemCgstAmountControllers.removeAt(index);
        itemSgstRateControllers.removeAt(index);
        itemSgstAmountControllers.removeAt(index);
        
        // Update SNo
        for (int i = 0; i < itemSnoControllers.length; i++) {
          itemSnoControllers[i].text = (i + 1).toString();
        }
      });
    }
  }

  void _loadSavedEntries() {
    final entries = ocrBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    setState(() {
      _savedEntries = entries;
    });

  }

  String? _selectedPlanNo;
  String? _selectedGateNo;
  String? _selectedBaseType;

  List<String> planNos = ["Plant 1", "Plant 2", "Plant 3",'Plant 4','Plant 5','Plant 6','Plant 7','Plant 8','Plant 9','Plant 10'];
  List<String> gateNos = ["Gate 1", "Gate 2", "Gate 3",'Gate 4','Gate 5','Gate 6','Gate 7','Gate 8','Gate 9','Gate 10'];


// Future<void> _pickImage(ImageSource source) async {
//   if (_selectedPlanNo == null || _selectedGateNo == null || _selectedBaseType == null) {
//     _showSnackBar("Please select Plan, Gate, and Base Type first!");
//     return;
//   }

//   try {
//     // Check camera permission if using camera
//     if (source == ImageSource.camera) {
//       final status = await Permission.camera.request();
//       if (!status.isGranted) {
//         _showSnackBar("Camera permission is required to capture images");
//         return;
//       }
//     }

//     final picked = await _picker.pickImage(
//       source: source,
//       preferredCameraDevice: CameraDevice.rear,
//       maxWidth: 1200,
//       maxHeight: 1200,
//       imageQuality: 85,
//     );
    
//     if (picked == null) return;

//     setState(() {
//       _imageFile = File(picked.path);
//       _isLoading = true;
//     });

//     // Use OCR.space API
//     final OCRSpaceRepository ocrSpaceRepo = OCRSpaceRepository();
//     final result = await ocrSpaceRepo.extractText(_imageFile!);
    
//     setState(() {
//       _isLoading = false;
//       // Fill main details
//       vendorNameCtrl.text = result["vendorName"] ?? "";
//       vendorCodeCtrl.text = result["vendorCode"] ?? "";
//       addressCtrl.text = result["address"] ?? "";
//       poDateCtrl.text = result["poDate"] ?? "";
//       invoiceDateCtrl.text = result["invoiceDate"] ?? "";
//       gstinNoCtrl.text = result["gstinNo"] ?? "";
//       poNoCtrl.text = result["poNo"] ?? "";
//       panNoCtrl.text = result["panNo"] ?? "";
//       grandTotalCtrl.text = result["grandTotal"] ?? "";
//       taxableAmountCtrl.text = result["taxableAmount"] ?? "";
//       invoiceNoCtrl.text = result["invoiceNo"] ?? "";
      
//       // Fill line items
//       List<Map<String, dynamic>> lineItems = List<Map<String, dynamic>>.from(result["lineItems"] ?? []);
//       _fillLineItemsControllers(lineItems);
//     });
    
//     _showSnackBar(" OCR Complete! ${itemDescriptionControllers.length} items detected", Colors.green);
    
//   } catch (e) {
//     setState(() {
//       _isLoading = false;
//     });
//     print("Camera Error: $e");
//     _showSnackBar(" Error: ${e.toString()}");
//   }
// }


// _pickImage method ko update karein
Future<void> _pickImage(ImageSource source) async {
  if (_selectedPlanNo == null || _selectedGateNo == null || _selectedBaseType == null) {
    _showSnackBar("Please select Plan, Gate, and Base Type first!");
    return;
  }

  try {
    // Check camera permission if using camera
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showSnackBar("Camera permission is required to capture images");
        return;
      }
    }

    final picked = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _isLoading = true;
    });

    final newOCRRepo = NewOCRAPIRepository();
    final result = await newOCRRepo.extractText(_imageFile!);
    
    setState(() {
      _isLoading = false;
      // Fill main details - DIRECT MAPPING
      vendorNameCtrl.text = result["vendorName"] ?? "";
      vendorCodeCtrl.text = result["vendorCode"] ?? "";
      addressCtrl.text = result["address"] ?? "";
      poDateCtrl.text = result["poDate"] ?? "";
      invoiceDateCtrl.text = result["invoiceDate"] ?? "";
      gstinNoCtrl.text = result["gstinNo"] ?? "";
      poNoCtrl.text = result["poNo"] ?? "";
      panNoCtrl.text = result["panNo"] ?? "";
      grandTotalCtrl.text = result["grandTotal"] ?? "";
      taxableAmountCtrl.text = result["taxableAmount"] ?? "";
      invoiceNoCtrl.text = result["invoiceNo"] ?? "";
      remarksCtrl.text = result["remarks"]?? "";
      vehicleCtrl.text = result["vehicleNo"]??"";
      drivernameCtrl.text = result["driverName"]??"";
      
      // Fill line items
      List<Map<String, dynamic>> lineItems = List<Map<String, dynamic>>.from(result["lineItems"] ?? []);
      _fillLineItemsControllers(lineItems);
    });
    
    _showSnackBar("✅ Data extracted successfully!", Colors.green);
    
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print("New OCR API Error: $e");
    _showSnackBar("Error: ${e.toString()}");
  }
}




  void _fillLineItemsControllers(List<Map<String, dynamic>> lineItems) {
    // Clear existing
    _clearAllItemControllers();
    
    // Add detected items
    for (int i = 0; i < lineItems.length; i++) {
      final item = lineItems[i];
      setState(() {
        itemSnoControllers.add(TextEditingController(text: item['sno']?.toString() ?? (i + 1).toString()));
        itemDescriptionControllers.add(TextEditingController(text: item['description']?.toString() ?? "Product Item"));
        itemHsnControllers.add(TextEditingController(text: item['hsnCode']?.toString() ?? ""));
        itemQuantityControllers.add(TextEditingController(text: item['quantity']?.toString() ?? "1"));
        itemRateControllers.add(TextEditingController(text: item['rate']?.toString() ?? "0.00"));
        itemAmountControllers.add(TextEditingController(text: item['amount']?.toString() ?? "0.00"));
        itemCgstRateControllers.add(TextEditingController(text: item['cgstRate']?.toString() ?? "9"));
        itemCgstAmountControllers.add(TextEditingController(text: item['cgstAmount']?.toString() ?? "0.00"));
        itemSgstRateControllers.add(TextEditingController(text: item['sgstRate']?.toString() ?? "9"));
        itemSgstAmountControllers.add(TextEditingController(text: item['sgstAmount']?.toString() ?? "0.00"));
      });
    }
    
    if (lineItems.isEmpty) {
      _addItemControllers();
    }
  }

  void _clearAllItemControllers() {
    setState(() {
      itemSnoControllers.clear();
      itemDescriptionControllers.clear();
      itemHsnControllers.clear();
      itemQuantityControllers.clear();
      itemRateControllers.clear();
      itemAmountControllers.clear();
      itemCgstRateControllers.clear();
      itemCgstAmountControllers.clear();
      itemSgstRateControllers.clear();
      itemSgstAmountControllers.clear();
    });
  }

  void _showSnackBar(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveData() {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please fill all required fields!");
      return;
    }

      final gateEntryNumber = _generateGateEntryNumber();


    List<Map<String, dynamic>> lineItems = [];
    for (int i = 0; i < itemSnoControllers.length; i++) {
      lineItems.add({
        "sno": itemSnoControllers[i].text,
        "description": itemDescriptionControllers[i].text,
        "hsnCode": itemHsnControllers[i].text,
        "quantity": itemQuantityControllers[i].text,
        "rate": itemRateControllers[i].text,
        "amount": itemAmountControllers[i].text,
        "cgstRate": itemCgstRateControllers[i].text,
        "cgstAmount": itemCgstAmountControllers[i].text,
        "sgstRate": itemSgstRateControllers[i].text,
        "sgstAmount": itemSgstAmountControllers[i].text,
      });
    }

    final data = {
      "vendorName": vendorNameCtrl.text,
      "vendorCode": vendorCodeCtrl.text,
      "address": addressCtrl.text,
      "poDate": poDateCtrl.text,
      "invoiceDate": invoiceDateCtrl.text,
      "gstinNo": gstinNoCtrl.text,
      "poNo": poNoCtrl.text,
      "panNo": panNoCtrl.text,
      "grandTotal": grandTotalCtrl.text,
      "taxableAmount": taxableAmountCtrl.text,
      "lineItems": lineItems,
      "planNo": _selectedPlanNo,
      "gateNo": _selectedGateNo,
      "baseType": _selectedBaseType,
      "invoiceNo": invoiceNoCtrl.text,
      "gateEntryNumber": gateEntryNumber, 
      "remarks":remarksCtrl.text,
      "vehicleNo":vehicleCtrl.text,
      "driverName":drivernameCtrl.text,

      "timestamp": DateTime.now().toString(),
    };
    _clearAllFields();
    
    ocrBox.add(data);

    //  _showSuccessDialog(gateEntryNumber);

    Navigator.push(context, MaterialPageRoute(builder: (context) => SavedEntriesScreen(savedEntries: [..._savedEntries, data])));
    _showSnackBar(" Gate generate successfully Gate No $gateEntryNumber!", Colors.green);
   
    _showSuccessDialog(gateEntryNumber);


  }



  void _clearAllFields() {
    setState(() {
      vendorNameCtrl.clear();
      vendorCodeCtrl.clear();
      addressCtrl.clear();
      poDateCtrl.clear();
      invoiceDateCtrl.clear();
      gstinNoCtrl.clear();
      poNoCtrl.clear();
      panNoCtrl.clear();
      invoiceNoCtrl.clear();
      grandTotalCtrl.clear();
      taxableAmountCtrl.clear();
      remarksCtrl.clear();
      vehicleCtrl.clear();
      drivernameCtrl.clear();
      _selectedPlanNo = null;
      _selectedGateNo = null;
      _selectedBaseType = null;
      _imageFile = null;
      _clearAllItemControllers();
      _addItemControllers();
    });
  }

 // Mobile Optimized Line Items Section
  Widget _buildLineItemsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.list_alt, size: 20, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("Line Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.green),
                  onPressed: _addItemControllers,
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Items List - Mobile Friendly
            ...List.generate(itemSnoControllers.length, (index) => 
              _buildMobileItemCard(index)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileItemCard(int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with SNo and Delete
            Row(
              children: [
                Text("Item ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Spacer(),
                if (itemSnoControllers.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _removeItemControllers(index),
                  ),
              ],
            ),
            Divider(),
            
            // Description
            _buildMobileItemField("Description*", itemDescriptionControllers[index], Icons.description, isRequired: false),
            
            // Basic Details Row
            Row(
              children: [
                Expanded(child: _buildMobileItemField("HSN", itemHsnControllers[index], Icons.code)),
                SizedBox(width: 8),
                Expanded(child: _buildMobileItemField("Qty", itemQuantityControllers[index], Icons.numbers)),
              ],
            ),
            
            // Price Details Row
            Row(
              children: [
                Expanded(child: _buildMobileItemField("Rate", itemRateControllers[index], Icons.currency_rupee_outlined)),
                SizedBox(width: 8),
                Expanded(child: _buildMobileItemField("Amount", itemAmountControllers[index], Icons.money)),
              ],
            ),
             
            // GST Header
            // Padding(
            //   padding: const EdgeInsets.only(top: 8, bottom: 4),
            //   child: Text("GST Details", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600])),
            // ),
            
            // CGST Row
            // Row(
            //   children: [
            //     Expanded(
            //       flex: 2,
            //       child: _buildMobileItemField("CGST %", itemCgstRateControllers[index], Icons.percent),
            //     ),
            //     SizedBox(width: 8),
            //     Expanded(
            //       flex: 3,
            //       child: _buildMobileItemField("CGST Amount", itemCgstAmountControllers[index], Icons.money),
            //     ),
            //   ],
            // ),
            
            // // SGST Row
            // Row(
            //   children: [
            //     Expanded(
            //       flex: 2,
            //       child: _buildMobileItemField("SGST %", itemSgstRateControllers[index], Icons.percent),
            //     ),
            //     SizedBox(width: 8),
            //     Expanded(
            //       flex: 3,
            //       child: _buildMobileItemField("SGST Amount", itemSgstAmountControllers[index], Icons.money),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileItemField(String label, TextEditingController controller, IconData icon, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
        validator: isRequired ? (value) {
          if (value == null || value.isEmpty) return 'Required';
          return null;
        } : null,
      ),
    );
  }

  Widget _buildFinancialSummary() {
    double itemsTotal = 0.0;
    for (var controller in itemAmountControllers) {
      try {
        double amount = double.tryParse(controller.text) ?? 0;
        itemsTotal += amount;
      } catch (e) {}
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, size: 20, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("Financial Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
          //  _buildFinancialRow("Items Total", "₹${itemsTotal.toStringAsFixed(2)}"),
            if (grandTotalCtrl.text.isNotEmpty)
              _buildFinancialRow("Grand Total ", "₹${grandTotalCtrl.text}"),
            // if (grandTotalCtrl.text.isNotEmpty)
            //   _buildFinancialRow("Grand Total", "₹${grandTotalCtrl.text}", isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: Colors.grey[600],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
          )),
          Text(value, style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green : Colors.black,
            fontSize: isTotal ? 16 : 14,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeaderCard(),
                SizedBox(height: 16),
                _buildSelectionSection(),
                SizedBox(height: 16),
                if (_imageFile != null) _buildImagePreview(),
                if (_isLoading) _buildLoadingIndicator(),
                //// Table
              //  _buildLineItemsSection(),
              _buildFormSection(),
                SizedBox(height: 12),
                _buildLineItemsSection(),
                   SizedBox(height: 12),

                _buildFinancialSummary(),
                SizedBox(height: 12),
               // _buildFormSection(),
                SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Rest of the UI methods (same as before with minor adjustments for mobile)
  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(icon: Icon(Icons.menu, color: Colors.white), onPressed: () {}),
      centerTitle: true,
      title: Text("GATE ENTRY PROCESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: Colors.white)),
      actions: [
        IconButton(icon: Icon(Icons.logout,color: Colors.white,), onPressed: () => _confirmLogout(context)),
        ValueListenableBuilder(
          valueListenable: Hive.box('ocr_entries').listenable(),
          builder: (context, Box box, _) {
            return Badge(
              label: Text(box.length.toString()),
              child: IconButton(icon: Icon(Icons.inventory_2_outlined,color: Colors.white,), onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SavedEntriesScreen(savedEntries: [])));
              }),
            );
          },
        ),
      ],
      backgroundColor: Colors.deepPurple,
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.deepPurple, Colors.purple]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.document_scanner, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text("Gate Entry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 5),
            Text("Scan invoice to auto-fill details", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }


  Widget _buildDateField(String label, TextEditingController controller, IconData icon, {bool isRequired = true}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: GestureDetector(
      onTap: () => _selectDate(context, controller),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            suffixIcon: Icon(Icons.calendar_today, size: 20),
            hintText: "DD/MM/YYYY",
          ),
          validator: isRequired ? (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (!_isValidDateFormat(v)) return 'Invalid date format';
            return null;
          } : null,
        ),
      ),
    ),
  );
}

// Date Picker Function
Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.deepPurple,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ),
        child: child!,
      );
    },
  );
  
  if (picked != null) {
    // Format: DD/MM/YYYY
    final formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    controller.text = formattedDate;
  }
}

// Date Format Validator
bool _isValidDateFormat(String dateStr) {
  try {
    List<String> parts = dateStr.split('/');
    if (parts.length != 3) return false;
    
    int day = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int year = int.parse(parts[2]);
    
    // Basic validation
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 2000 || year > 2100) return false;
    
    // Month-wise day validation
    if (month == 2) {
      if (day > 29) return false;
      if (day == 29 && !_isLeapYear(year)) return false;
    } else if ([4, 6, 9, 11].contains(month)) {
      if (day > 30) return false;
    }
    
    return true;
  } catch (e) {
    return false;
  }
}

bool _isLeapYear(int year) {
  return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
}





  Widget _buildSelectionSection() {
  return Column(
    children: [
      Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Configuration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              _buildDropdown("Plant No", _selectedPlanNo, planNos, (v) => setState(() => _selectedPlanNo = v)),
              SizedBox(height: 12),
              _buildDropdown("Gate No", _selectedGateNo, gateNos, (v) => setState(() => _selectedGateNo = v)),
              SizedBox(height: 12),
              _buildBaseTypeSelector(),
            ],
          ),
        ),
      ),
      if (_selectedBaseType == "PO " || _selectedBaseType == "POS Base") ...[
        SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [Icon(Icons.scanner), SizedBox(width: 8), Text("Scan Invoice", style: TextStyle(fontWeight: FontWeight.bold))]),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildScanButton("Camera", Icons.camera_alt, Colors.deepPurple, () => _pickImage(ImageSource.camera))),
                    SizedBox(width: 12),
                    Expanded(child: _buildScanButton("Gallery", Icons.photo_library, Colors.purple, () => _pickImage(ImageSource.gallery))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

  Widget _buildScanButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 12)),
      onPressed: onPressed,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 20), SizedBox(width: 6), Text(text)]),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20)
      )),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBaseTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Entry Type", style: TextStyle(color: Colors.grey)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildBaseTypeButton("PO ", Icons.point_of_sale)),
            SizedBox(width: 12),
            Expanded(child: _buildBaseTypeButton("Non PO", Icons.assignment_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildBaseTypeButton(String type, IconData icon) {
    bool isSelected = _selectedBaseType == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => setState(() => _selectedBaseType = type),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16), SizedBox(width: 6), Text(type, style: TextStyle(fontSize: 12))]),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [Icon(Icons.photo_library), SizedBox(width: 8), Text("Scanned Image", style: TextStyle(fontWeight: FontWeight.bold))]),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ImagePreviewScreen(imageFile: _imageFile!))),
              child: Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text("Processing OCR...")]),
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.description), SizedBox(width: 8), Text("Invoice Details", style: TextStyle(fontWeight: FontWeight.bold))]),
            SizedBox(height: 16),
            _buildTextField("P.O. No", poNoCtrl, Icons.numbers,isRequired: false),
            _buildDateField("P.O. Date", poDateCtrl, Icons.calendar_today,),
            _buildDateField("Invoice Date", invoiceDateCtrl, Icons.date_range,isRequired: false),
            _buildTextField("Invoice No", invoiceNoCtrl, Icons.receipt,isRequired: false),
            _buildTextField("Vendor Code", vendorCodeCtrl, Icons.code,isRequired: false),
            _buildTextField("Vendor Name", vendorNameCtrl, Icons.business),
            _buildTextField("GSTIN No", gstinNoCtrl, Icons.card_membership,isRequired: false),
            _buildTextField("PAN No", panNoCtrl, Icons.credit_card,isRequired: false),
            _buildTextField("Address", addressCtrl, Icons.location_on,isRequired: false),
            _buildTextField("Taxable Amount", taxableAmountCtrl, Icons.money, isRequired: false),
            _buildTextField("Grand Total", grandTotalCtrl, Icons.currency_rupee_rounded, isRequired: false),
            _buildTextField("Vehicle No", vehicleCtrl, Icons.filter_list, isRequired: false),
            _buildTextField("Driver Name", drivernameCtrl, Icons.business),
             _buildTextField("Remarks", remarksCtrl, Icons.filter_list, isRequired: false),


          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isRequired = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
        validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          icon: Icon(Icons.save), label: Text("SAVE INVOICE", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)),
          onPressed: _saveData,
        )),
        SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          icon: Icon(Icons.clear), label: Text("CLEAR ALL"),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red), padding: EdgeInsets.symmetric(vertical: 16)),
          onPressed: _clearAllFields,
        )),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text("Confirm Logout"),
      content: Text("Are you sure you want to logout?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen())), child: Text("Logout")),
      ],
    ));
  }
  
 // void _showSuccessDialog(String gateEntryNumber) {}

 void _showSuccessDialog(String gateEntryNumber) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 30),
          SizedBox(width: 10),
          Text("Success!", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Gate Entry created successfully!"),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.green),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Gate Entry Number", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(gateEntryNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("OK"),
        ),
      ],
    ),
  );
}



}

class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  const ImagePreviewScreen({super.key, required this.imageFile});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image Preview")),
      body: Center(child: InteractiveViewer(child: Image.file(imageFile, fit: BoxFit.contain))),
    );
  }
}


