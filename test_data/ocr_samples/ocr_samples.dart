/// OCR test dataset — 20+ real-world label text samples with expected outputs.
/// Each entry represents a realistic OCR reading from a product label or invoice.
library ocr_samples;

class OcrSample {
  final String id;
  final String rawText;
  final DateTime? expectedExpiry;
  final String? expectedProductName;
  final String description;

  const OcrSample({
    required this.id,
    required this.rawText,
    this.expectedExpiry,
    this.expectedProductName,
    required this.description,
  });
}

final List<OcrSample> ocrSamples = [
  // ── Pattern 1: DD/MM/YYYY ───────────────────────────────────────────────
  OcrSample(
    id: 'S01',
    description: 'Standard DD/MM/YYYY slash separator',
    rawText: 'MAGGI NOODLES\nMfg: 01/06/2026\nExp: 30/06/2027\nBest before date',
    expectedExpiry: DateTime(2027, 6, 30),
    expectedProductName: 'MAGGI NOODLES',
  ),
  OcrSample(
    id: 'S02',
    description: 'DD-MM-YYYY dash separator',
    rawText: 'BRITANNIA MARIE GOLD\nManufactured: 15-01-2026\nExpiry: 14-01-2027',
    expectedExpiry: DateTime(2027, 1, 14),
    expectedProductName: 'BRITANNIA MARIE GOLD',
  ),
  OcrSample(
    id: 'S03',
    description: 'DD.MM.YYYY dot separator',
    rawText: 'SUNFLOWER OIL 1L\nBest Before: 31.12.2026',
    expectedExpiry: DateTime(2026, 12, 31),
    expectedProductName: 'SUNFLOWER OIL',
  ),
  OcrSample(
    id: 'S04',
    description: 'EXP keyword prefix with DD/MM/YYYY',
    rawText: 'DOVE BEAUTY SOAP\nNet Wt: 75g\nEXP: 05/09/2027',
    expectedExpiry: DateTime(2027, 9, 5),
    expectedProductName: 'DOVE BEAUTY SOAP',
  ),

  // ── Pattern 2: MM/YYYY ──────────────────────────────────────────────────
  OcrSample(
    id: 'S05',
    description: 'MM/YYYY slash — typical pharma label',
    rawText: 'PARACETAMOL TABLETS IP 500mg\nMfd: 03/2026\nExp: 02/2028',
    expectedExpiry: DateTime(2028, 2, 1),
    expectedProductName: 'PARACETAMOL TABLETS',
  ),
  OcrSample(
    id: 'S06',
    description: 'MM-YYYY dash separator',
    rawText: 'CETAPHIL MOISTURISING CREAM\nBest Before: 08-2027',
    expectedExpiry: DateTime(2027, 8, 1),
    expectedProductName: 'CETAPHIL MOISTURISING CREAM',
  ),
  OcrSample(
    id: 'S07',
    description: 'Use by MM/YYYY',
    rawText: 'AMUL BUTTER\nUse by: 11/2026',
    expectedExpiry: DateTime(2026, 11, 1),
    expectedProductName: 'AMUL BUTTER',
  ),

  // ── Pattern 3: MMM YYYY (month name) ───────────────────────────────────
  OcrSample(
    id: 'S08',
    description: 'Short month name — JAN',
    rawText: 'HIMALAYA FACE WASH\nExp: JAN 2028',
    expectedExpiry: DateTime(2028, 1, 1),
    expectedProductName: 'HIMALAYA FACE WASH',
  ),
  OcrSample(
    id: 'S09',
    description: 'Short month name — DEC lowercase',
    rawText: 'JOHNSON BABY OIL\nBest Before: dec 2026',
    expectedExpiry: DateTime(2026, 12, 1),
    expectedProductName: 'JOHNSON BABY OIL',
  ),
  OcrSample(
    id: 'S10',
    description: 'Short month name — APR with use by prefix',
    rawText: 'KISSAN JAM\nUse by APR 2027',
    expectedExpiry: DateTime(2027, 4, 1),
    expectedProductName: 'KISSAN JAM',
  ),
  OcrSample(
    id: 'S11',
    description: 'Short month name — SEP',
    rawText: 'HEAD & SHOULDERS SHAMPOO\nExpiry: SEP 2026',
    expectedExpiry: DateTime(2026, 9, 1),
    expectedProductName: 'HEAD',
  ),
  OcrSample(
    id: 'S12',
    description: 'Short month name — FEB with multi-line label',
    rawText: 'DETTOL ANTISEPTIC\n500ml\nBatch No: DT2601\nExp: FEB 2028',
    expectedExpiry: DateTime(2028, 2, 1),
    expectedProductName: 'DETTOL ANTISEPTIC',
  ),

  // ── Keyword priority ────────────────────────────────────────────────────
  OcrSample(
    id: 'S13',
    description: 'Expiry keyword takes priority over manufacture date',
    rawText: 'TATA SALT\nMfg: 01/03/2026\nExp: 28/02/2028',
    expectedExpiry: DateTime(2028, 2, 28),
    expectedProductName: 'TATA SALT',
  ),
  OcrSample(
    id: 'S14',
    description: 'Best before with multiple dates — picks future date',
    rawText: 'PARLE G BISCUITS\nPacked: 10/01/2026\nBest Before: 09/07/2026',
    expectedExpiry: DateTime(2026, 7, 9),
    expectedProductName: 'PARLE G BISCUITS',
  ),

  // ── No expiry present ───────────────────────────────────────────────────
  OcrSample(
    id: 'S15',
    description: 'No date on label — returns null expiry',
    rawText: 'STAINLESS STEEL WATER BOTTLE\n1 Litre\nMade in India',
    expectedExpiry: null,
    expectedProductName: 'STAINLESS STEEL WATER BOTTLE',
  ),
  OcrSample(
    id: 'S16',
    description: 'Only lot number, no expiry date',
    rawText: 'Lot No: LT20260601\nBatch: B002\nNet Weight: 250g',
    expectedExpiry: null,
    expectedProductName: null,
  ),

  // ── Edge cases & noise ──────────────────────────────────────────────────
  OcrSample(
    id: 'S17',
    description: 'Expiry date only (no product name line)',
    rawText: 'Exp 12/2027',
    expectedExpiry: DateTime(2027, 12, 1),
    expectedProductName: null,
  ),
  OcrSample(
    id: 'S18',
    description: 'Multi-line with noise: barcodes, weights, asterisks',
    rawText: '***\n8906003450123\nMOMO MASALA SPICE MIX\n50g\nMfg: 04/2026\nExpiry: 03/2028\n***',
    expectedExpiry: DateTime(2028, 3, 1),
    expectedProductName: 'MOMO MASALA SPICE MIX',
  ),
  OcrSample(
    id: 'S19',
    description: 'OCR noise: month name with mixed case',
    rawText: 'BOROLINE CREAM\nBest Before: Aug 2027',
    expectedExpiry: DateTime(2027, 8, 1),
    expectedProductName: 'BOROLINE CREAM',
  ),
  OcrSample(
    id: 'S20',
    description: 'Year out of range — should return null',
    rawText: 'OLD STOCK ITEM\nExp: 15/06/2000',
    expectedExpiry: null,
    expectedProductName: 'OLD STOCK ITEM',
  ),
  OcrSample(
    id: 'S21',
    description: 'Future out-of-range year — should return null',
    rawText: 'LONG SHELF ITEM\nExpiry: 01/01/2099',
    expectedExpiry: null,
    expectedProductName: 'LONG SHELF ITEM',
  ),
  OcrSample(
    id: 'S22',
    description: 'MAR month name',
    rawText: 'POND\'S TALC\nExpiry Date: MAR 2027',
    expectedExpiry: DateTime(2027, 3, 1),
    expectedProductName: 'TALC',
  ),
  OcrSample(
    id: 'S23',
    description: 'JUL month name',
    rawText: 'LIFEBUOY SOAP\nExpiry: JUL 2028',
    expectedExpiry: DateTime(2028, 7, 1),
    expectedProductName: 'LIFEBUOY SOAP',
  ),
];
