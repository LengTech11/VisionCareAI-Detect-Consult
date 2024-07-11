import 'dart:io';

import 'package:dio/dio.dart';
import 'package:disease_detector_app/config/themes/color.dart';
import 'package:disease_detector_app/provider/disease_provider.dart';
import 'package:disease_detector_app/utils/custom_text_theme/custom_text_theme.dart';
import 'package:disease_detector_app/utils/helper/helper_function.dart';
import 'package:disease_detector_app/widgets/eca_listtile.dart';
import 'package:disease_detector_app/widgets/eca_show_btm_sheet.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _predictedClass;
  double? _confidence;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DiseaseProvider>(context, listen: false);
    provider.fetchDisease();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _predictDisease();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error picking image: $e');
    }
  }

  Future<void> _predictDisease() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_image!.path),
      });
      final response =
          await dio.post('http://10.0.2.2:5000/predict', data: formData);

      if (response.statusCode == 200) {
        setState(() {
          _predictedClass = response.data['Predicted Class'].toString();
          _confidence = response.data['Confidence'];
        });
        // ignore: use_build_context_synchronously
        _showPredictionBottomSheet(context);
      } else {
        setState(() {
          _predictedClass = 'Failed to predict';
          _confidence = null;
        });
      }
    } catch (e) {
      print('Error predicting disease: $e');
      setState(() {
        _predictedClass = 'Failed to predict';
        _confidence = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPredictionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.none,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3, // Half screen on initial display
        minChildSize: 0.3, // Minimum screen size
        maxChildSize: 0.8, // Full screen on drag
        expand: false, // Don't expand automatically
        builder: (context, scrollController) {
          final dark = HelperFunctions.isDarkMode(context);
          return Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 10,
                  left: MediaQuery.of(context).size.width / 2 - 25,
                  child: Container(
                    alignment: Alignment.topCenter,
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prediction Result',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Disease: ',
                                style: dark
                                    ? MyTextTheme.darkTextTheme.titleLarge
                                    : MyTextTheme.lightTextTheme.titleLarge,
                              ),
                              TextSpan(
                                text: _predictedClass ?? 'Unknown',
                                style: dark
                                    ? MyTextTheme.darkTextTheme.titleLarge
                                    : MyTextTheme.lightTextTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: Colors.grey,
                          height: 20,
                          thickness: 2,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Confidence: ',
                                    style: dark
                                        ? MyTextTheme.darkTextTheme.titleLarge
                                        : MyTextTheme.lightTextTheme.titleLarge,
                                  ),
                                  TextSpan(
                                    text: _confidence != null
                                        ? '${(_confidence! * 100).toStringAsFixed(2)}%'
                                        : 'N/A',
                                    style: dark
                                        ? MyTextTheme.darkTextTheme.titleLarge
                                        : MyTextTheme.lightTextTheme.titleLarge,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _confidence ?? 0,
                                backgroundColor: Colors.grey[200],
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(
                          color: Colors.grey,
                          height: 20,
                          thickness: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildContent(context),
      ),
    );
  }

  Widget buildListDiseases(BuildContext context) {
    return Consumer<DiseaseProvider>(
      builder: (context, value, _) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: value.dis?.data.length,
          itemBuilder: (BuildContext context, int index) {
            var disease = value.dis?.data[index];
            if (disease == null) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: EcaListtile(
                  leading: const Icon(
                    Icons.visibility,
                    color: AppColor.primary,
                  ),
                  title: Text(disease.title),
                  onTap: () => ECABtmSheet.ecaShowBtmSheet(
                      context: context,
                      title: disease.title,
                      description: disease.description),
                ),
              );
            }
          },
        );
      },
      // child: ,
    );
  }

  Widget buildContent(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 65),
          buildUploadImageContent(context),
          const SizedBox(height: 20),
          buildDescription(context),
          const SizedBox(height: 20),
          buildListDiseases(context),
          const SizedBox(height: 20),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget buildUploadImageContent(BuildContext context) {
    final dark = HelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ListTile(
          leading: const Icon(
            Icons.note_alt_outlined,
            size: 35,
            color: Color(0xFF3F51B5),
          ),
          title: Text(
            'Please upload an image of the eye disease here',
            style: dark
                ? MyTextTheme.darkTextTheme.titleLarge
                : MyTextTheme.lightTextTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 20),
        DottedBorder(
          dashPattern: const [9, 9],
          color: const Color(0xFF3F51B5),
          strokeWidth: 1.5,
          child: Container(
            height: 260,
            width: 260,
            color: Colors.white,
            child: buildUploadImageButton(context),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget buildUploadImageButton(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: InkWell(
            onTap: _pickImage,
            child: Container(
              height: 260,
              width: 260,
              color: Theme.of(context).colorScheme.secondary,
              child: _image == null
                  ? const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 50,
                      color: Color(0xFF3F51B5),
                    )
                  : Image.file(
                      _image!,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        const Positioned(
          bottom: 40,
          left: 170,
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 35,
            color: Color(0xFF3F51B5),
          ),
        ),
      ],
    );
  }

  Widget buildDescription(BuildContext context) {
    final dark = HelperFunctions.isDarkMode(context);
    return Text(
      'After uploading the image, you can view information about various eye diseases below:',
      style: dark
          ? MyTextTheme.darkTextTheme.titleLarge
          : MyTextTheme.lightTextTheme.titleLarge,
    );
  }
}
