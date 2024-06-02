class MicroscopeParams {
  late String processId;
  late int timePerPxl = 500;
  late int proportionalFeedback = 1;
  late int integralFeedback = 1;
  late int differentialFeedback = 1;
  late int sizeInPxl = 10;
  late int sizeInNm = 100;
  late int sampleBias = 100;
  late int tunnelingCurrent = 100;
  late String sampleName = "";
  late String tipName = "";

  Map toJson() => {
    'processId': processId,
    'timePerPxl': timePerPxl.toString(),
    'proportionalFeedback': proportionalFeedback.toString(),
    'integralFeedback': integralFeedback.toString(),
    'differentialFeedback': differentialFeedback.toString(),
    'sizeInPxl': sizeInPxl.toString(),
    'sizeInNm': sizeInNm.toString(),
    'sampleBias': sampleBias.toString(),
    'tunnelingCurrent': tunnelingCurrent.toString(),
    'sampleName': sampleName,
    'tipName': tipName,
  };


  void setValue(String input, String? dropdownSelectedValue) {
    switch (dropdownSelectedValue) {
      case "-1":
        break;
      case "0":
        timePerPxl = int.tryParse(input)!;
        break;
      case "1":
        proportionalFeedback = int.tryParse(input)!;
        break;
      case "2":
        integralFeedback = int.tryParse(input)!;
        break;
      case "3":
        differentialFeedback = int.tryParse(input)!;
        break;
      case "4":
        sizeInPxl = int.tryParse(input)!;
        break;
      case "5":
        sizeInNm = int.tryParse(input)!;
        break;
      case "6":
        sampleBias = int.tryParse(input)!;
        break;
      case "7":
        tunnelingCurrent = int.tryParse(input)!;
        break;
      case "8":
        sampleName = input;
        break;
      case "9":
        tipName = input;
        break;
    }
  }
}