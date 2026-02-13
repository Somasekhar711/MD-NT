class AppConfig {
  // Update this IP whenever your hotspot/network changes
  static const String ipAddress = '172.31.179.241'; 
  
  static const String baseUrl = 'http://$ipAddress:5000/api/auth';
}