import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> exportProductsToExcel() async {
    // Créer un nouveau workbook
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // Ajouter les en-têtes
    sheet.getRangeByName('A1').setText('ID');
    sheet.getRangeByName('B1').setText('Nom');
    sheet.getRangeByName('C1').setText('Description');
    sheet.getRangeByName('D1').setText('Quantité');
    sheet.getRangeByName('E1').setText('Seuil Critique');
    sheet.getRangeByName('F1').setText('Dernière Mise à Jour');

    // Récupérer les produits depuis Firestore
    final QuerySnapshot products = await _firestore.collection('products').get();
    
    // Remplir les données
    int row = 2;
    for (var doc in products.docs) {
      final data = doc.data() as Map<String, dynamic>;
      sheet.getRangeByName('A$row').setText(doc.id);
      sheet.getRangeByName('B$row').setText(data['name'] ?? '');
      sheet.getRangeByName('C$row').setText(data['description'] ?? '');
      sheet.getRangeByName('D$row').setNumber(data['quantity'] ?? 0);
      sheet.getRangeByName('E$row').setNumber(data['criticalThreshold'] ?? 0);
      sheet.getRangeByName('F$row').setText(data['lastUpdated']?.toDate().toString() ?? '');
      row++;
    }

    // Mettre en forme les en-têtes
    final Range headerRange = sheet.getRangeByName('A1:F1');
    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.backColor = '#4472C4';
    headerRange.cellStyle.fontColor = '#FFFFFF';

    // Ajuster la largeur des colonnes
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);
    sheet.autoFitColumn(4);
    sheet.autoFitColumn(5);
    sheet.autoFitColumn(6);

    // Sauvegarder le fichier
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // Obtenir le répertoire de stockage
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/inventory_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }
} 