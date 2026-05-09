/// Selectable PDF layout templates for invoices and quotations.
enum PdfTemplate {
  classic,
  modern,
  minimal;

  /// Human-readable display name shown in the settings picker.
  String get label => switch (this) {
        PdfTemplate.classic => 'Classic',
        PdfTemplate.modern => 'Modern',
        PdfTemplate.minimal => 'Minimal',
      };

  /// Short description shown below the label in the settings picker.
  String get description => switch (this) {
        PdfTemplate.classic => 'Clean layout with coloured accents',
        PdfTemplate.modern => 'Bold indigo header band, light table',
        PdfTemplate.minimal => 'Plain black & white, no colours',
      };

  /// Deserialise from a database string (e.g. "classic"). Falls back to
  /// [PdfTemplate.classic] for unknown / null values.
  static PdfTemplate fromString(String? value) => PdfTemplate.values
      .firstWhere((e) => e.name == value, orElse: () => PdfTemplate.classic);
}
