class FormException implements Exception{
  String message;
  FormException(String error){
    this.message=error;
  }
  @override
  String toString() {
    return "$message";
  }
}