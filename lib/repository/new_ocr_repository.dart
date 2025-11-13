import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class NewOCRAPIRepository {
  static const String _apiUrl = 'http://82.25.105.67:5000/extract';

  Future<Map<String, dynamic>> extractText(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResult = json.decode(responseData);

       return _parseStructuredData(jsonResult);
      
    } catch (e) {
      print('New OCR API Error: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  Map<String, dynamic> _parseStructuredData(Map<String, dynamic> response) {
    Map<String, dynamic> result = {
      "vendorName": "",
      "vendorCode": "",
      "address": "",
      "poDate": "",
      "invoiceDate": "",
      "gstinNo": "",
      "poNo": "",
      "panNo": "",
      "invoiceNo": "",
      "grandTotal": "",
      "taxableAmount": "",
      "remarks":"",
      "vehicleNo":"",
      "driverName":"",
      "lineItems": [],
    };


    try {
      // Extract from key_values
      if (response.containsKey('key_values')) {
        Map<String, dynamic> keyValues = response['key_values'];
        _extractFromKeyValues(keyValues, result);
      }

      // Extract from tables
      if (response.containsKey('tables')) {
        List<dynamic> tables = response['tables'];
        _extractFromTables(tables, result);
      }

      print(' Parsed Result: $result');

    } catch (e) {
      print('Structured data parsing error: $e');
    }

    return result;
  }


  void _extractFromKeyValues(Map<String, dynamic> keyValues, Map<String, dynamic> result) {

    // Vendor Name
    result["vendorName"] = _getValue(keyValues, [
      'Vender Name :', 'Vendor Name :', 'Vender Name', 'Vendor Name',
      'Ac. Name :-', 'Company Name', 'Seller','A/c Holders Name :',"A/c Holder's Name :","A/c Holder's Name"
    ]);



    // remarks
    result["remarks"] = _getValue(keyValues, [
      "Remarks :-","Remarks :- ","Remarks :-",'Remarks'
    ]);

    
    // vehicleNo
    result["vehicleNo"] = _getValue(keyValues, [
     'Vehicle No. :', "vehicleNo :-","vehicleNo ","Vehicle No. :",
    ]);

   
    // driverName
    result["driverName"] = _getValue(keyValues, [
      "Driver Name :","Driver Name : ",'Driver Name :'
    ]);

    
    

    // Vendor Code
    result["vendorCode"] = _getValue(keyValues, [
      'Vender Code :', 'Vendor Code :', 'Vender Code', 'Vendor Code',
      'Supplier Code', 'Vendor ID'
    ]);


    // Invoice Number
    result["invoiceNo"] = _getValue(keyValues, [
      'Invoice No. :', 'Invoice No.', 'Invoice No', 'Invoice Number',
      'Inv No', 'INV No'
    ]);

    // Invoice Date
    result["invoiceDate"] = _getValue(keyValues, [
      'Invoice Date :', 'Invoice Date', 'Date', 'Invoice Dated',
      'Bill Date', 'Document Date'
    ]);

    // PO Number
    result["poNo"] = _getValue(keyValues, [
      'P.O. No. :', 'P.O. No.', 'PO No', 'Purchase Order No',
      'PO Number', 'Order No'
    ]);

    // PO Date
    result["poDate"] = _getValue(keyValues, [
      'P.O. Date :', 'P.O. Date', 'PO Date', 'Order Date',
      'Purchase Order Date'
    ]);

    
        //  GSTIN Number - FIXED (Space removed)
       result["gstinNo"] = _getValue(keyValues, [
      'GSTIN NO :-', 'GSTIN :-', 'GSTIN', 'GST No', 'GSTIN:', //  FIXED - No space
      'GST Number', 'GSTIN No', 'GSTIN/UIN:', 'GSTIN/UIN', 
      'GSTIN/UIN":', 'GSTIN/UIN :', 'GSTIN/UIN"',"GSTIN NO :-"
    ]);


    // PAN Number
    result["panNo"] = _getValue(keyValues, [
      'PAN No. :-', 'PAN No', 'PAN', 'PAN/IT NO','PAN No. :-','PAN/IT No',"PAN No. :-"
    ]);

    // Grand Total
    result["grandTotal"] = _getValue(keyValues, [
      'Grand Total', 'Total Amount', 'Amount', 'Final Amount',
      'Net Amount', 'Invoice Total'
    ]);

    // Taxable Amount
    result["taxableAmount"] = _getValue(keyValues, [
      'Taxable Amount', 'Subtotal', 'Base Amount', 'Amount Before Tax'
    ]);

    
     
    // Address - IMPROVED
    result["address"] = _getValue(keyValues, [
      'Address :', 'Address', 'Billing Address', 'Company Address',
      'SAMEER IT CARE' // Use company name as address if no specific address
    ]);

    

  }

  void _extractFromTables(List<dynamic> tables, Map<String, dynamic> result) {
    for (var table in tables) {
      if (table is List) {
        for (var row in table) {
          if (row is List && row.length >= 3) {
            // Look for key-value pairs in tables
            String firstCell = row[0]?.toString() ?? '';
            String secondCell = row[1]?.toString() ?? '';
            String thirdCell = row[2]?.toString() ?? '';

            // Invoice Number from table
            if (result["invoiceNo"]!.isEmpty && 
                _containsAny(firstCell.toLowerCase(), ['invoice no', 'invoice number'])) {
              result["invoiceNo"] = thirdCell.isNotEmpty ? thirdCell : secondCell;
            }

            // Invoice Date from table
            if (result["invoiceDate"]!.isEmpty && 
                _containsAny(firstCell.toLowerCase(), ['invoice date', 'date'])) {
              result["invoiceDate"] = thirdCell.isNotEmpty ? thirdCell : secondCell;
            }

            // Extract line items from the main items table
            _extractLineItemsFromTable(row, result);
          }
        }
      }

      

    }
  }


  void _extractLineItemsFromTable(List<dynamic> row, Map<String, dynamic> result) {
  // Check if this row looks like a line item (has numbers in quantity/rate/amount)
  if (row.length >= 6) {
    try {
      String sno = row[0]?.toString() ?? '';
      String description = row[1]?.toString() ?? '';
      String hsnCode = row[2]?.toString() ?? '';
      String quantity = row[3]?.toString() ?? '';
      String rate = row[4]?.toString() ?? '';
      String amount = row[5]?.toString() ?? '';

      // Skip summary/total rows
      if (_isSummaryRow(description, sno, hsnCode, quantity, rate, amount)) {
        print('⏭️ Skipping summary row: $description');
        return;
      }

      // Check if this is a valid line item (has description and numbers)
      if (description.isNotEmpty && 
          description.length > 3 && 
          !_containsAny(description.toLowerCase(), ['description', 'sno', 'hsn', 'qty', 'total']) &&
          (double.tryParse(quantity) != null || double.tryParse(rate) != null)) {
        
        Map<String, dynamic> item = {
          "sno": sno.isNotEmpty ? sno : (result["lineItems"]!.length + 1).toString(),
          "description": description,
          "hsnCode": hsnCode,
          "quantity": quantity.isNotEmpty ? quantity : "1",
          "rate": rate.isNotEmpty ? rate : "0.00",
          "amount": amount.isNotEmpty ? amount : "0.00",
          "cgstRate": "9",
          "cgstAmount": "0.00",
          "sgstRate": "9", 
          "sgstAmount": "0.00",
        };

        result["lineItems"].add(item);
        print('✅ Added line item: $description');
      }
    } catch (e) {
      print('Line item extraction error: $e');
    }
  }
}

bool _isSummaryRow(String description, String sno, String hsnCode, String quantity, String rate, String amount) {
  if (_containsAny(description.toLowerCase(), ['total', 'subtotal', 'summary', 'grand total'])) {
    return true;
  }
  
  if (description == "Total" && quantity == "6" && amount.isEmpty && hsnCode.isEmpty) {
    return true;
  }
  
  
  if (description.isEmpty && quantity.isNotEmpty && double.tryParse(quantity) != null) {
    return true;
  }
  
  // Check if it's a header row
  if (_containsAny(description.toLowerCase(), ['sno', 'description', 'hsn', 'qty', 'rate', 'amt'])) {
    return true;
  }
  
  return false;
}

 String _getValue(Map<String, dynamic> keyValues, List<String> possibleKeys) {
    for (String key in possibleKeys) {
      if (keyValues.containsKey(key)) {
        String value = keyValues[key]?.toString() ?? '';
        if (value.isNotEmpty && value != 'null' && value != 'NOT_SELECTED') {
          print('✅ Found $key: $value');
          return value;
        }
      }

    }
    return '';
  }


  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }



  
}
