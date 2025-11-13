import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class OCRSpaceRepository {
  final String apiKey = 'K86253039788957';
   //  final String apiKey = 'K84637507588957';

  final String apiUrl = 'https://api.ocr.space/parse/image';

  Future<Map<String, dynamic>> extractText(File imageFile) async {
    try {
      print("=== USING OCR.SPACE API ===");
      
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      
      // EXACT SAME PARAMETERS AS POSTMAN
      request.headers['apikey'] = apiKey;
      request.fields['language'] = 'eng';
      request.fields['isOverlayRequired'] = 'true';
      request.fields['isTable'] = 'true';
      request.fields['scale'] = 'true';
      request.fields['isCreateSearchablePdf'] = 'true';
      request.fields['isSearchablePdfHideTextLayer'] = 'true';
      request.fields['filetype'] = 'jpg'; // Fixed filetype
      
      // Get dynamic filename with correct extension
      String dynamicFileName = _getDynamicFileName(imageFile);
      print(" Uploading file: $dynamicFileName");
      
      // Add image file - EXACTLY LIKE POSTMAN
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // This should be 'file' not 'url'
          imageFile.path,
          filename: dynamicFileName,
        ),
      );

      print(" Sending request to OCR.space...");
      print(" Parameters used:");
      print("  - language: eng");
      print("  - isOverlayRequired: false");
      print("  - isTable: true");
      print("  - scale: true");
      print("  - filetype: jpg");
      print("  - filename: $dynamicFileName");
      
      // Send request with timeout
      var response = await request.send().timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('OCR processing timeout after 60 seconds');
        },
      );
      
      var responseData = await response.stream.bytesToString();
      var jsonResult = jsonDecode(responseData);

      print("=== OCR.SPACE API RESPONSE ===");
      print("Status: ${jsonResult['OCRExitCode']}");
      print("Error: ${jsonResult['IsErroredOnProcessing']}");
      
      if (jsonResult['IsErroredOnProcessing'] == true) {
        String errorMessage = jsonResult['ErrorMessage']?[0] ?? 'Unknown error';
        print(" API Error Message: $errorMessage");
        throw Exception('OCR Space API Error: $errorMessage');
      }

      String extractedText = '';
      if (jsonResult['ParsedResults'] != null && jsonResult['ParsedResults'].length > 0) {
        extractedText = jsonResult['ParsedResults'][0]['ParsedText'] ?? '';
      }

      print("=== EXTRACTED TEXT FROM OCR.SPACE ===");
      print(extractedText.isNotEmpty ? "Text extracted successfully (${extractedText.length} characters)" : "No text extracted");
      if (extractedText.length > 500) {
        print("First 500 chars: ${extractedText.substring(0, 500)}...");
      } else {
        print(extractedText);
      }
      print("=== END EXTRACTED TEXT ===");

      if (extractedText.isEmpty) {
        throw Exception('No text extracted from image');
      }

      return _processOCRText(extractedText);

    } on TimeoutException catch (e) {
      print(' OCR Timeout Error: $e');
      throw Exception('OCR processing took too long. Please try with a smaller image or better connection.');
    } catch (e) {
      print(' OCR Space API Error: $e');
      throw Exception('OCR Failed: ${e.toString()}');
    }
  }

  String _getDynamicFileName(File imageFile) {
    try {
      String originalName = imageFile.path.split('/').last;
      print(" Original filename: $originalName");
      
      if (originalName.isNotEmpty && originalName.contains('.')) {
        String nameWithoutExt = originalName.split('.').first;
        String extension = originalName.split('.').last.toLowerCase();
        
        // Ensure valid extension
        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          return '${nameWithoutExt}_$timestamp.$extension';
        } else {
          // If invalid extension, use jpg
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          return 'image_$timestamp.jpg';
        }
      } else {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        return 'image_$timestamp.jpg';
      }
    } catch (e) {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'image_$timestamp.jpg';
    }
  }

 
 
  Map<String, dynamic> _processOCRText(String text) {
    print("=== PROCESSING EXTRACTED TEXT ===");
    
    Map<String, dynamic> extractedData = {
      "vendorName": _extractVendorName(text),
      "vendorCode": _extractVendorCode(text),
      "address": _extractAddress(text),
      "poDate": _extractPODate(text),
      "invoiceDate": _extractInvoiceDate(text),
      "invoiceNo": _extractInvoiceNo(text),
      "gstinNo": _extractGSTIN(text),
      "poNo": _extractPONo(text),
      "panNo": _extractPAN(text),
      "lineItems": _extractLineItemsFromOCR(text),
      "grandTotal": _extractGrandTotal(text),
      "taxableAmount": _extractTaxableAmount(text),
    };

    print("=== EXTRACTED DATA ===");
    extractedData.forEach((key, value) {
      if (key == "lineItems") {
        print("$key: ${value.length} items");
        for (var item in value) {
          print("  - ${item['sno']}. ${item['description']} | HSN: ${item['hsnCode']} | Qty: ${item['quantity']} | Rate: ₹${item['rate']} | Amount: ₹${item['amount']}");
        }
      } else {
        print("$key: $value");
      }
    });
    print("=== END EXTRACTED DATA ===");

    return extractedData;
  }




//   String? _extractInvoiceNo(String text) {
//   final patterns = [
//     RegExp(r'Invoice No\.?\s*:\s*([A-Z0-9/_-]+)', caseSensitive: false),
//     RegExp(r'Inv\.? No\.?\s*:\s*([A-Z0-9/_-]+)', caseSensitive: false),
//     RegExp(r'Bill No\.?\s*:\s*([A-Z0-9/_-]+)', caseSensitive: false),
//   ];
  
//   for (var pattern in patterns) {
//     final match = pattern.firstMatch(text);
//     if (match != null) {
//       String invoiceNo = match.group(1)!.trim();
//       print(" Invoice No Found: $invoiceNo");
//       return invoiceNo;
//     }
//   }
  
//   // Look for common invoice number patterns
//   RegExp invoicePattern = RegExp(r'[A-Z]{2,6}/[0-9]{2,4}/[0-9]{2,4}/[0-9]{3,5}');
//   var match = invoicePattern.firstMatch(text);
//   if (match != null) {
//     String invoiceNo = match.group(0)!;
//     print(" Invoice Pattern Found: $invoiceNo");
//     return invoiceNo;
//   }
  
//   print(" Invoice No Not Found");
//   return null;
// }




String? _extractInvoiceNo(String text) {
  final patterns = [
    RegExp(r'Invoice\s*No\.?\s*:?\s*([A-Z0-9/_-]+)', caseSensitive: false, dotAll: true),
    RegExp(r'Inv\.?\s*No\.?\s*:?\s*([A-Z0-9/_-]+)', caseSensitive: false, dotAll: true),
    RegExp(r'Bill\s*No\.?\s*:?\s*([A-Z0-9/_-]+)', caseSensitive: false, dotAll: true),
  ];
  
  for (var pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String invoiceNo = match.group(1)!.trim();
      print("Invoice No Found: $invoiceNo");
      return invoiceNo;
    }
  }
  
  // Common invoice format
  RegExp invoicePattern = RegExp(r'[A-Z]{2,6}/[0-9]{2,4}/[0-9]{2,4}/[0-9]{3,5}');
  var match = invoicePattern.firstMatch(text);
  if (match != null) {
    String invoiceNo = match.group(0)!;
    print("Invoice Pattern Found: $invoiceNo");
    return invoiceNo;
  }
  
  print("Invoice No Not Found");
  return null;
}


  // MAIN: Dynamic Line Items Extraction
  List<Map<String, dynamic>> _extractLineItemsFromOCR(String text) {
    List<Map<String, dynamic>> lineItems = [];
    
    print("=== EXTRACTING LINE ITEMS DYNAMICALLY ===");
    
    List<String> lines = text.split('\n');
    
    // Print relevant lines for debugging
    print(" TOTAL LINES: ${lines.length}");
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isNotEmpty) {
        print("$i: $line");
      }
    }
    
    // Method 1: Extract from structured table
    lineItems = _extractFromTableStructure(lines);
    
    // Method 2: Comprehensive line-by-line extraction
    if (lineItems.length < 5) {
      print(" Few items found, trying comprehensive extraction...");
      List<Map<String, dynamic>> additionalItems = _extractAllProductLines(lines);
      lineItems.addAll(additionalItems);
    }
    
    // Remove duplicates and clean items
    lineItems = _removeDuplicateItems(lineItems);
    lineItems = _validateAndCleanItems(lineItems);
    
    print(" TOTAL ITEMS EXTRACTED: ${lineItems.length}");
    return lineItems;
  }

  // Extract from table structure with multiple strategies
  List<Map<String, dynamic>> _extractFromTableStructure(List<String> lines) {
    List<Map<String, dynamic>> items = [];
    bool inTable = false;
    int itemCounter = 1;
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      // Look for table header
      if (_isTableHeader(line)) {
        inTable = true;
        print(" TABLE HEADER FOUND at line $i: $line");
        continue;
      }
      
      // Process table rows
      if (inTable) {
        // Check for table end
        if (_isTableEnd(line)) {
          print(" TABLE ENDED at line $i: $line");
          break;
        }
        
        // Skip empty lines and header-like lines
        if (line.isEmpty || _isTableHeader(line) || line.contains('---') || 
            (line.contains('Code') && line.contains('(Nos)'))) {
          continue;
        }
        
        // Try multiple parsing strategies for each line
        Map<String, dynamic>? product = _parseLineWithMultipleStrategies(line, itemCounter);
        if (product != null) {
          items.add(product);
          itemCounter++;
          print(" TABLE ITEM ${items.length}: ${product['description']}");
        } else {
          print(" SKIPPED LINE: $line");
        }
      }
    }
    
    return items;
  }

  // Parse line with multiple dynamic strategies
  Map<String, dynamic>? _parseLineWithMultipleStrategies(String line, int sno) {
    // Strategy 1: Tab-separated parsing (most accurate for OCR.space)
    Map<String, dynamic>? product = _parseTabSeparatedLine(line, sno);
    if (product != null) return product;
    
    // Strategy 2: Space-separated parsing with flexible serial number
    product = _parseSpaceSeparatedLine(line, sno);
    if (product != null) return product;
    
    // Strategy 3: Pattern-based parsing for difficult lines
    product = _parseWithPatterns(line, sno);
    
    return product;
  }

  // Parse tab-separated lines (OCR.space preserves tabs)
  Map<String, dynamic>? _parseTabSeparatedLine(String line, int sno) {
    try {
      if (!line.contains('\t')) return null;
      
      print(" PARSING TAB-SEPARATED LINE: $line");
      
      List<String> columns = line.split('\t')
          .where((col) => col.trim().isNotEmpty)
          .map((col) => col.trim())
          .toList();
      
      if (columns.length < 3) {
        print(" Not enough tab columns: ${columns.length}");
        return null;
      }
      
      print(" Tab Columns: $columns");
      
      // Analyze column structure dynamically
      int descIndex = 0;
      int hsnIndex = -1;
      int amountIndex = -1;
      
      // Find description column (usually first non-serial column)
      if (_isValidSerialNumber(columns[0])) {
        descIndex = 1;
      } else {
        descIndex = 0;
      }
      
      if (descIndex >= columns.length) return null;
      
      String description = columns[descIndex];
      
      // Find HSN column (look for 4-8 digit numbers)
      for (int i = descIndex + 1; i < columns.length; i++) {
        if (_isValidHSN(columns[i])) {
          hsnIndex = i;
          break;
        }
      }
      
      // Find amount column (look for money patterns from the end)
      for (int i = columns.length - 1; i > descIndex; i--) {
        String amount = _extractAmountFromText(columns[i]);
        if (amount != "0.00") {
          amountIndex = i;
          break;
        }
      }
      
      if (amountIndex == -1) {
        print(" No amount found in tab columns");
        return null;
      }
      
      String amount = _extractAmountFromText(columns[amountIndex]);
      String hsnCode = hsnIndex != -1 ? columns[hsnIndex] : "";
      
      // Try to find quantity and rate
      String quantity = "1";
      String rate = amount; // Default to amount if rate not found
      
      // Look for quantity before amount
      for (int i = descIndex + 1; i < amountIndex; i++) {
        String potentialQty = _extractNumber(columns[i]);
        if (_isValidQuantity(potentialQty)) {
          quantity = potentialQty;
          // Next column might be rate
          if (i + 1 < amountIndex) {
            String potentialRate = _extractAmountFromText(columns[i + 1]);
            if (potentialRate != "0.00") {
              rate = potentialRate;
            }
          }
          break;
        }
      }
      
      if (!_isValidProductDescription(description) || !_isValidAmount(amount)) {
        return null;
      }
      
      return _createProductItem(sno, description, hsnCode, quantity, rate, amount);
      
    } catch (e) {
      print(' Error parsing tab-separated line: $e');
      return null;
    }
  }

  // Parse space-separated lines with flexible serial number
  Map<String, dynamic>? _parseSpaceSeparatedLine(String line, int sno) {
    try {
      print(" PARSING SPACE-SEPARATED LINE: $line");
      
      String cleanLine = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      List<String> parts = cleanLine.split(' ');
      
      if (parts.length < 3) return null;
      
      // Dynamic analysis of parts
      int descStartIndex = 0;
      int dataStartIndex = -1;
      
      // Check if first part is serial number
      if (_isValidSerialNumber(parts[0])) {
        descStartIndex = 1;
      }
      
      // Find where data starts (HSN or numbers)
      for (int i = descStartIndex; i < parts.length; i++) {
        if (_isValidHSN(parts[i]) || _isValidAmount(parts[i]) || _isNumber(parts[i])) {
          dataStartIndex = i;
          break;
        }
      }
      
      if (dataStartIndex == -1 || dataStartIndex <= descStartIndex) {
        print(" Could not find data start");
        return null;
      }
      
      String description = parts.sublist(descStartIndex, dataStartIndex).join(' ').trim();
      
      if (!_isValidProductDescription(description)) {
        return null;
      }
      
      // Extract data from remaining parts
      String hsnCode = "";
      String quantity = "1";
      String rate = "0.00";
      String amount = "0.00";
      
      List<String> numbers = [];
      for (int i = dataStartIndex; i < parts.length; i++) {
        String number = _extractAmountFromText(parts[i]);
        if (number != "0.00") {
          numbers.add(number);
        }
        if (_isValidHSN(parts[i])) {
          hsnCode = parts[i];
        }
      }
      
      if (numbers.isNotEmpty) {
        amount = numbers.last;
        if (numbers.length >= 2) rate = numbers[numbers.length - 2];
        if (numbers.length >= 3) quantity = numbers[numbers.length - 3];
      }
      
      if (amount == "0.00") {
        amount = _extractAmountFromLine(line);
      }
      
      if (!_isValidAmount(amount)) {
        return null;
      }
      
      return _createProductItem(sno, description, hsnCode, quantity, rate, amount);
      
    } catch (e) {
      print(' Error parsing space-separated line: $e');
      return null;
    }
  }

  // Pattern-based parsing for difficult lines
  Map<String, dynamic>? _parseWithPatterns(String line, int sno) {
    try {
      print(" PARSING WITH PATTERNS: $line");
      
      // Pattern 1: Description followed by amount
      RegExp pattern1 = RegExp(r'([A-Za-z][^0-9]*?)\s+(\d+\.\d{2})');
      var match1 = pattern1.firstMatch(line);
      if (match1 != null) {
        String description = match1.group(1)!.trim();
        String amount = match1.group(2)!;
        
        if (_isValidProductDescription(description) && _isValidAmount(amount)) {
          String hsnCode = _extractHSNFromLine(line);
          return _createProductItem(sno, description, hsnCode, "1", amount, amount);
        }
      }
      
      // Pattern 2: Serial, Description, Amount
      RegExp pattern2 = RegExp(r'(\d+)\s+([A-Za-z].*?)\s+(\d+\.\d{2})');
      var match2 = pattern2.firstMatch(line);
      if (match2 != null) {
        String description = match2.group(2)!.trim();
        String amount = match2.group(3)!;
        
        if (_isValidProductDescription(description) && _isValidAmount(amount)) {
          String hsnCode = _extractHSNFromLine(line);
          return _createProductItem(sno, description, hsnCode, "1", amount, amount);
        }
      }
      
      // Pattern 3: Description with HSN and Amount
      RegExp pattern3 = RegExp(r'([A-Za-z].*?)\s+(\d{4,8})\s+(\d+\.\d{2})');
      var match3 = pattern3.firstMatch(line);
      if (match3 != null) {
        String description = match3.group(1)!.trim();
        String hsnCode = match3.group(2)!;
        String amount = match3.group(3)!;
        
        if (_isValidProductDescription(description) && _isValidAmount(amount)) {
          return _createProductItem(sno, description, hsnCode, "1", amount, amount);
        }
      }
      
      return null;
      
    } catch (e) {
      print(' Error parsing with patterns: $e');
      return null;
    }
  }

  // Extract all potential product lines
  List<Map<String, dynamic>> _extractAllProductLines(List<String> lines) {
    List<Map<String, dynamic>> items = [];
    int itemCounter = 1;
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      if (line.isEmpty || _isNonProductLine(line)) {
        continue;
      }
      
      // Try to parse as product line
      Map<String, dynamic>? product = _parseLineWithMultipleStrategies(line, itemCounter);
      if (product != null) {
        items.add(product);
        itemCounter++;
        print(" ADDITIONAL ITEM: ${product['description']}");
      }
    }
    
    return items;
  }

  // Remove duplicate items
  List<Map<String, dynamic>> _removeDuplicateItems(List<Map<String, dynamic>> items) {
    List<Map<String, dynamic>> uniqueItems = [];
    Set<String> seenDescriptions = Set();
    
    for (var item in items) {
      String description = item['description'].toString().toLowerCase().trim();
      
      if (!seenDescriptions.contains(description)) {
        uniqueItems.add(item);
        seenDescriptions.add(description);
      }
    }
    
    return uniqueItems;
  }

  // Validate and clean items
  List<Map<String, dynamic>> _validateAndCleanItems(List<Map<String, dynamic>> items) {
    List<Map<String, dynamic>> cleanedItems = [];
    
    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      String description = item['description'].toString().trim();
      String amount = item['amount'].toString();
      
      // Skip if description is invalid or amount is invalid
      if (_isValidProductDescription(description) && _isValidAmount(amount)) {
        // Update SNo
        item['sno'] = (cleanedItems.length + 1).toString();
        cleanedItems.add(item);
      }
    }
    
    return cleanedItems;
  }

  // Create product item
  Map<String, dynamic> _createProductItem(int sno, String description, String hsnCode, String quantity, String rate, String amount) {
    double amountValue = double.parse(amount);
    double cgstAmount = (amountValue * 9) / 100;
    double sgstAmount = (amountValue * 9) / 100;
    
    return {
      "sno": sno.toString(),
      "description": description,
      "hsnCode": hsnCode,
      "quantity": quantity,
      "rate": rate,
      "amount": amount,
      "cgstRate": "9",
      "cgstAmount": cgstAmount.toStringAsFixed(2),
      "sgstRate": "9",
      "sgstAmount": sgstAmount.toStringAsFixed(2),
    };
  }

  // HELPER METHODS
  bool _isTableHeader(String line) {
    String upperLine = line.toUpperCase();
    
    List<String> headerPatterns = [
      'SNO', 'SR.NO', 'SR NO', 'NO.', 'ITEM',
      'DESCRIPTION', 'PRODUCT', 'GOODS', 'ITEM DESCRIPTION',
      'HSN', 'SAC', 'CODE', 'HSN/SAC',
      'QTY', 'QUANTITY', 'NOS',
      'RATE', 'PRICE', 'UNIT PRICE',
      'AMOUNT', 'AMT', 'TOTAL', 'VALUE'
    ];
    
    int matches = 0;
    for (String pattern in headerPatterns) {
      if (upperLine.contains(pattern)) {
        matches++;
      }
    }
    
    bool isHeader = matches >= 3;
    
    if (isHeader) {
      print(" TABLE HEADER IDENTIFIED (Matches: $matches): $line");
    }
    
    return isHeader;
  }

  bool _isTableEnd(String line) {
    String upperLine = line.toUpperCase();
    return upperLine.contains('TOTAL') || 
           upperLine.contains('BANK') || 
           upperLine.contains('GRAND') ||
           upperLine.contains('TAXABLE') ||
           upperLine.contains('AMOUNT IN WORDS');
  }

  bool _isNonProductLine(String line) {
    String upperLine = line.toUpperCase();
    return upperLine.contains('TOTAL') ||
           upperLine.contains('BANK') ||
           upperLine.contains('GSTIN') ||
           upperLine.contains('PAN') ||
           upperLine.contains('ADDRESS') ||
           upperLine.contains('DATE') ||
           upperLine.contains('INVOICE') ||
           upperLine.contains('PHONE') ||
           upperLine.contains('CONTACT') ||
           upperLine.contains('TERMS') ||
           upperLine.contains('CONDITIONS') ||
           upperLine.contains('CERTIFIED') ||
           upperLine.contains('THANK') ||
           upperLine.contains('SIGNATURE') ||
           line.length < 5;
  }

  bool _isValidSerialNumber(String text) {
    return RegExp(r'^\d+$').hasMatch(text);
  }

  bool _isValidHSN(String text) {
    return RegExp(r'^\d{4,8}$').hasMatch(text);
  }

  bool _isNumber(String text) {
    return RegExp(r'^\d+\.?\d*$').hasMatch(text) && double.tryParse(text) != null;
  }

  bool _isValidAmount(String text) {
    if (text.isEmpty) return false;
    double? amount = double.tryParse(text);
    return amount != null && amount > 0 && amount < 1000000;
  }

  bool _isValidQuantity(String text) {
    if (text.isEmpty) return false;
    int? qty = int.tryParse(text);
    return qty != null && qty > 0 && qty < 1000;
  }

  bool _isValidProductDescription(String description) {
    if (description.length < 3) return false;
    
    List<String> invalidPatterns = [
      'total', 'bank', 'gstin', 'pan', 'address', 'date', 'invoice',
      'phone', 'contact', 'terms', 'conditions', 'certified', 'thank',
      'signature', 'authorized', 'receiver', 'remarks', 'code', 'nos'
    ];
    
    String upperDesc = description.toUpperCase();
    
    for (String pattern in invalidPatterns) {
      if (upperDesc.contains(pattern.toUpperCase())) {
        return false;
      }
    }
    
    bool hasLetters = RegExp(r'[A-Za-z]').hasMatch(description);
    bool notJustNumbers = !RegExp(r'^\d+$').hasMatch(description);
    
    return hasLetters && notJustNumbers && (description.split(' ').length >= 2 || description.length > 10);
  }

  String _extractNumber(String text) {
    RegExp numberRegex = RegExp(r'(\d+\.?\d*)');
    var match = numberRegex.firstMatch(text);
    return match?.group(0) ?? "0.00";
  }

  String _extractAmountFromText(String text) {
    RegExp amountRegex = RegExp(r'(\d+[,.]?\d*\.\d{2})');
    var match = amountRegex.firstMatch(text);
    if (match != null) {
      String amount = match.group(0)!.replaceAll(',', '');
      double? amountValue = double.tryParse(amount);
      if (amountValue != null && amountValue > 0 && amountValue < 1000000) {
        return amount;
      }
    }
    return "0.00";
  }

  String _extractAmountFromLine(String line) {
    return _extractAmountFromText(line);
  }

  String _extractHSNFromLine(String line) {
    RegExp hsnRegex = RegExp(r'\b\d{4,8}\b');
    var match = hsnRegex.firstMatch(line);
    return match?.group(0) ?? "";
  }

  int max(int a, int b) => a > b ? a : b;
  int min(int a, int b) => a < b ? a : b;

  // // EXISTING EXTRACTION METHODS (Keep them as they are working)
  // String? _extractVendorName(String text) {
  //   final patterns = [
  //     RegExp(r'Vender Name\s*:\s*([A-Za-z0-9\s&\.]+)', caseSensitive: false),
  //     RegExp(r'Vendor Name\s*:\s*([A-Za-z0-9\s&\.]+)', caseSensitive: false),
  //   ];
    
  //   for (var pattern in patterns) {
  //     final match = pattern.firstMatch(text);
  //     if (match != null) {
  //       String vendorName = match.group(1)!.trim();
  //       if (vendorName.length > 2) {
  //         return vendorName;
  //       }
  //     }
  //   }
  //   return null;
  // }

  // String? _extractVendorCode(String text) {
  //   final patterns = [
  //     RegExp(r'Vender Code\s*:\s*([0-9]+)', caseSensitive: false),
  //     RegExp(r'Vendor Code\s*:\s*([0-9]+)', caseSensitive: false),
  //   ];
    
  //   for (var pattern in patterns) {
  //     final match = pattern.firstMatch(text);
  //     if (match != null) {
  //       return match.group(1)!.trim();
  //     }
  //   }
  //   return null;
  // }


  String? _extractVendorName(String text) {
  final patterns = [
    RegExp(r'Vender\s*Name\s*:\s*([A-Za-z0-9\s&\.\-]+)(?=\s*Vender\s*Code|$)', caseSensitive: false),
    RegExp(r'Vendor\s*Name\s*:\s*([A-Za-z0-9\s&\.\-]+)(?=\s*Vendor\s*Code|$)', caseSensitive: false),
    RegExp(r'Vender\s*Name\s*:\s*([^\n\r:]+?)(?=\s*(?:Vender\s*Code|Vendor\s*Code|$))', caseSensitive: false),
    RegExp(r'Vendor\s*Name\s*:\s*([^\n\r:]+?)(?=\s*(?:Vender\s*Code|Vendor\s*Code|$))', caseSensitive: false),
  ];
  
  for (var pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String vendorName = match.group(1)!.trim();
      // Clean up the vendor name - remove any numbers that might be vendor code
      vendorName = vendorName.replaceAll(RegExp(r'\s*\d+$'), '').trim();
      
      if (vendorName.length > 2 && !_containsOnlyNumbers(vendorName)) {
        print(" Vendor Name Found: '$vendorName'");
        return vendorName;
      }
    }
  }

  // Fallback: Look for vendor name patterns without code
  final fallbackPatterns = [
    RegExp(r'Vender\s*Name\s*:\s*([A-Za-z\s&\.\-]+)', caseSensitive: false),
    RegExp(r'Vendor\s*Name\s*:\s*([A-Za-z\s&\.\-]+)', caseSensitive: false),
  ];
  
  for (var pattern in fallbackPatterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String vendorName = match.group(1)!.trim();
      if (vendorName.length > 2) {
        print(" Vendor Name (Fallback) Found: '$vendorName'");
        return vendorName;
      }
    }
  }
  
  print(" Vendor Name Not Found");
  return null;
}

String? _extractVendorCode(String text) {
  final patterns = [
    RegExp(r'Vender\s*Code\s*:\s*(\d+)', caseSensitive: false),
    RegExp(r'Vendor\s*Code\s*:\s*(\d+)', caseSensitive: false),
    RegExp(r'(?<=Vender\s*Name\s*:[^\n]*?)\s*(\d+)(?=\s|$)', caseSensitive: false),
    RegExp(r'(?<=Vendor\s*Name\s*:[^\n]*?)\s*(\d+)(?=\s|$)', caseSensitive: false),
  ];
  
  for (var pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String vendorCode = match.group(1)!.trim();
      print(" Vendor Code Found: '$vendorCode'");
      return vendorCode;
    }
  }

  // Additional pattern to extract vendor code that might be stuck with vendor name
  RegExp stuckPattern = RegExp(r'Vender\s*Name\s*:\s*[A-Za-z\s]+?(\d+)', caseSensitive: false);
  final stuckMatch = stuckPattern.firstMatch(text);
  if (stuckMatch != null) {
    String vendorCode = stuckMatch.group(1)!.trim();
    print(" Vendor Code (Stuck Pattern) Found: '$vendorCode'");
    return vendorCode;
  }
  
  print(" Vendor Code Not Found");
  return null;
}

// Helper method to check if string contains only numbers
bool _containsOnlyNumbers(String str) {
  return RegExp(r'^\d+$').hasMatch(str);
}






  String? _extractAddress(String text) {
    final addressPattern = RegExp(r'Address\s*:\s*([^\n]+[\s\S]*?)(?=GSTIN|PAN|P\.O|$)', caseSensitive: false);
    final match = addressPattern.firstMatch(text);
    
    if (match != null) {
      String address = match.group(1)!.trim();
      address = address.replaceAll('Address :', '').trim();
      return address.split('GSTIN').first.trim();
    }
    return null;
  }




//////////////////////////////////////


// IMPROVED DATE EXTRACTION
String? _extractPODate(String text) {
  final patterns = [
    RegExp(r'P\.O\.\s*Date\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
    RegExp(r'PO\s*Date\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
    RegExp(r'P\.O\.\s*Date\s*:\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
    RegExp(r'PO\s*Date\s*:\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
    RegExp(r'Date\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
  ];
  
  for (var pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String date = match.group(1)!.trim();
      if (_isValidDate(date)) {
        print("✅ PO Date Found: $date");
        return date;
      }
    }
  }
  
  // Look for date patterns near "P.O." text
  RegExp poDatePattern = RegExp(r'P\.O\.[^\d]*(\d{1,2}/\d{1,2}/\d{4})');
  var poMatch = poDatePattern.firstMatch(text);
  if (poMatch != null) {
    String date = poMatch.group(1)!.trim();
    if (_isValidDate(date)) {
      print("✅ PO Date (Pattern) Found: $date");
      return date;
    }
  }
  
  print("❌ PO Date Not Found");
  return null;
}

String? _extractInvoiceDate(String text) {
  final patterns = [
    RegExp(r'Invoice\s*Date\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
    RegExp(r'Invoice\s*Date\s*:\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
    RegExp(r'Date\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
    RegExp(r'Bill\s*Date\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
  ];
  
  for (var pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String date = match.group(1)!.trim();
      if (_isValidDate(date)) {
        print("✅ Invoice Date Found: $date");
        return date;
      }
    }
  }
  
  // Look for date patterns after "Invoice" text
  RegExp invoiceDatePattern = RegExp(r'Invoice[^\d]*(\d{1,2}/\d{1,2}/\d{4})');
  var invoiceMatch = invoiceDatePattern.firstMatch(text);
  if (invoiceMatch != null) {
    String date = invoiceMatch.group(1)!.trim();
    if (_isValidDate(date)) {
      print("✅ Invoice Date (Pattern) Found: $date");
      return date;
    }
  }
  
  // Extract all dates and find the most likely invoice date
  List<String> allDates = _extractAllDates(text);
  if (allDates.isNotEmpty) {
    // Prefer dates that are after PO date if available
    String? poDate = _extractPODate(text);
    if (poDate != null) {
      for (String date in allDates) {
        if (_isDateAfter(date, poDate)) {
          print("✅ Invoice Date (After PO) Found: $date");
          return date;
        }
      }
    }
    // Otherwise return the first valid date that's not PO date
    for (String date in allDates) {
      if (date != poDate && _isValidDate(date)) {
        print("✅ Invoice Date (First Valid) Found: $date");
        return date;
      }
    }
  }
  
  print("❌ Invoice Date Not Found");
  return null;
}

// IMPROVED GSTIN EXTRACTION
String? _extractGSTIN(String text) {
  final patterns = [
    RegExp(r'GSTIN\s*NO\s*([A-Z0-9]{15})', caseSensitive: false),
    RegExp(r'GSTIN\s*:\s*([A-Z0-9]{15})', caseSensitive: false),
    RegExp(r'GSTIN\s*([A-Z0-9]{15})', caseSensitive: false),
    RegExp(r'GST\s*:\s*([A-Z0-9]{15})', caseSensitive: false),
    RegExp(r'GSTIN NO\s*:\s*-\s*([A-Z0-9]{15})', caseSensitive: false),
  ];
  
  for (var pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String gstin = match.group(1)!.trim().toUpperCase();
      if (_isValidGSTIN(gstin)) {
        print("✅ GSTIN Found: $gstin");
        return gstin;
      }
    }
  }
  
  // Look for GSTIN pattern with possible OCR errors
  RegExp gstinPattern = RegExp(r'[0-9]{2}[A-Z]{4,5}[0-9]{4}[A-Z]{1}[A-Z0-9]{1}[Z]{1}[A-Z0-9]{1}');
  var matches = gstinPattern.allMatches(text);
  for (var match in matches) {
    String gstin = match.group(0)!.toUpperCase();
    if (_isValidGSTIN(gstin)) {
      print("✅ GSTIN Pattern Found: $gstin");
      return gstin;
    }
  }
  
  // Try to find GSTIN near "GSTIN" text
  RegExp nearGstin = RegExp(r'GSTIN[^\n]*?([A-Z0-9]{10,15})');
  var nearMatch = nearGstin.firstMatch(text);
  if (nearMatch != null) {
    String potentialGstin = nearMatch.group(1)!.trim().toUpperCase();
    if (_isValidGSTIN(potentialGstin)) {
      print("✅ GSTIN (Near Text) Found: $potentialGstin");
      return potentialGstin;
    }
  }
  
  print("❌ GSTIN Not Found");
  return null;
}

// IMPROVED PAN EXTRACTION
String? _extractPAN(String text) {
  final patterns = [
    RegExp(r'PAN\s*No\.\s*:\s*-\s*([A-Z]{5}[0-9]{4}[A-Z]{1})', caseSensitive: false),
    RegExp(r'PAN\s*No\.\s*:\s*([A-Z]{5}[0-9]{4}[A-Z]{1})', caseSensitive: false),
    RegExp(r'PAN\s*:\s*([A-Z]{5}[0-9]{4}[A-Z]{1})', caseSensitive: false),
    RegExp(r'PAN\s*([A-Z]{5}[0-9]{4}[A-Z]{1})', caseSensitive: false),
  ];
  
  for (var pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      String pan = match.group(1)!.trim().toUpperCase();
      if (_isValidPAN(pan)) {
        print("✅ PAN Found: $pan");
        return pan;
      }
    }
  }
  
  // Look for PAN pattern with possible OCR errors
  RegExp panPattern = RegExp(r'[A-Z]{4,5}[0-9]{4}[A-Z]{1}');
  var matches = panPattern.allMatches(text);
  for (var match in matches) {
    String pan = match.group(0)!.toUpperCase();
    if (_isValidPAN(pan)) {
      print("✅ PAN Pattern Found: $pan");
      return pan;
    }
  }
  
  // Try to find PAN near "PAN" text
  RegExp nearPan = RegExp(r'PAN[^\n]*?([A-Z0-9]{8,10})');
  var nearMatch = nearPan.firstMatch(text);
  if (nearMatch != null) {
    String potentialPan = nearMatch.group(1)!.trim().toUpperCase();
    if (_isValidPAN(potentialPan)) {
      print("✅ PAN (Near Text) Found: $potentialPan");
      return potentialPan;
    }
  }
  
  print("❌ PAN Not Found");
  return null;
}

// NEW HELPER METHODS
List<String> _extractAllDates(String text) {
  RegExp datePattern = RegExp(r'\b(\d{1,2}/\d{1,2}/\d{4})\b');
  var matches = datePattern.allMatches(text);
  List<String> dates = [];
  
  for (var match in matches) {
    String date = match.group(1)!;
    if (_isValidDate(date)) {
      dates.add(date);
    }
  }
  
  return dates;
}

bool _isDateAfter(String date1, String date2) {
  try {
    List<String> parts1 = date1.split('/');
    List<String> parts2 = date2.split('/');
    
    DateTime dt1 = DateTime(int.parse(parts1[2]), int.parse(parts1[1]), int.parse(parts1[0]));
    DateTime dt2 = DateTime(int.parse(parts2[2]), int.parse(parts2[1]), int.parse(parts2[0]));
    
    return dt1.isAfter(dt2) || dt1.isAtSameMomentAs(dt2);
  } catch (e) {
    return false;
  }
}

bool _isValidGSTIN(String gstin) {
  if (gstin.length != 15) return false;
  
  // Basic GSTIN format validation
  RegExp gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}[Z]{1}[0-9A-Z]{1}$');
  return gstinRegex.hasMatch(gstin);
}

bool _isValidPAN(String pan) {
  if (pan.length != 10) return false;
  
  // Basic PAN format validation
  RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  return panRegex.hasMatch(pan);
}

bool _isValidDate(String dateStr) {
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

  // String? _extractPODate(String text) {
  //   final patterns = [
  //     RegExp(r'P\.O\. Date\s*:\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
  //   ];
    
  //   for (var pattern in patterns) {
  //     final match = pattern.firstMatch(text);
  //     if (match != null && _isValidDate(match.group(1)!)) {
  //       return match.group(1)!.trim();
  //     }
  //   }
  //   return null;
  // }
  
  

  // String? _extractInvoiceDate(String text) {
  //   final patterns = [
  //     RegExp(r'Invoice Date\s*:\s*(\d{1,2}/\d{1,2}/\d{4})', caseSensitive: false),
  //   ];
    
  //   for (var pattern in patterns) {
  //     final match = pattern.firstMatch(text);
  //     if (match != null && _isValidDate(match.group(1)!)) {
  //       return match.group(1)!.trim();
  //     }
  //   }
  //   return null;
  // }

  // String? _extractGSTIN(String text) {
  //   final patterns = [
  //     RegExp(r'GSTIN NO\s*:\s*-\s*([A-Z0-9]{15})', caseSensitive: false),
  //   ];
    
  //   for (var pattern in patterns) {
  //     final match = pattern.firstMatch(text);
  //     if (match != null) {
  //       return match.group(1)!.trim();
  //     }
  //   }
  //   return null;
  // }

  String? _extractPONo(String text) {
    final patterns = [
      RegExp(r'P\.O\. No\.\s*:\s*([0-9]+)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  // String? _extractPAN(String text) {
  //   final patterns = [
  //     RegExp(r'PAN No\.\s*:\s*-\s*([A-Z0-9]{10})', caseSensitive: false),
  //   ];
    
  //   for (var pattern in patterns) {
  //     final match = pattern.firstMatch(text);
  //     if (match != null) {
  //       return match.group(1)!.trim();
  //     }
  //   }
  //   return null;
  // }

  String? _extractGrandTotal(String text) {
    final patterns = [
      RegExp(r'Grand Total\s*[\s\S]*?(\d+[\d,]*\.\d{2})', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.replaceAll(',', '').trim();
      }
    }
    return null;
  }

  String? _extractTaxableAmount(String text) {
    final patterns = [
      RegExp(r'Taxable Amount\s*[\s\S]*?(\d+[\d,]*\.\d{2})', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.replaceAll(',', '').trim();
      }
    }
    return null;
  }

  // bool _isValidDate(String dateStr) {
  //   try {
  //     List<String> parts = dateStr.split('/');
  //     if (parts.length != 3) return false;
  //     int day = int.parse(parts[0]);
  //     int month = int.parse(parts[1]);
  //     int year = int.parse(parts[2]);
  //     return month >= 1 && month <= 12 && day >= 1 && day <= 31;
  //   } catch (e) {
  //     return false;
  //   }
  // }
}







