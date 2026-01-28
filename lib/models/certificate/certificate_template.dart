class CertificateTemplate {
  final String id;
  final String name;
  final String templateHtml;
  final String? templateCss;
  final String? backgroundImageUrl;
  final String? signatureImageUrl;
  final Map<String, dynamic> defaultFields;
  final bool isActive;

  CertificateTemplate({
    required this.id,
    required this.name,
    required this.templateHtml,
    this.templateCss,
    this.backgroundImageUrl,
    this.signatureImageUrl,
    this.defaultFields = const {},
    this.isActive = true,
  });
}