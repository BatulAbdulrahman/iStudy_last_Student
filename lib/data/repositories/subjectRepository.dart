import 'package:dio/dio.dart';
import 'package:eschool/data/models/lesson.dart';
import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/utils/api.dart';

class SubjectRepository {
Future<List<Lesson>> getLessons({
  required int classSubjectId,
  required int childId,
  required bool useParentApi,
}) async {
  try {
    print("Fetching lessons with:");
    print("  classSubjectId: $classSubjectId");
    print("  childId: $childId");
    print("  useParentApi: $useParentApi"); // Confirm this is correct

    Map<String, dynamic> queryParameters = {
      "class_subject_id": classSubjectId,
    };

    if (useParentApi) {
      queryParameters["child_id"] = childId;
    }

    final result = await Api.get(
      url:
          useParentApi ? Api.lessonsOfSubjectParent : Api.getLessonsOfSubject,
      useAuthToken: true,
      queryParameters: queryParameters,
    );

    print("API Response: ${result}");
    return (result['data'] as List)
        .map((lesson) => Lesson.fromJson(Map.from(lesson)))
        .toList();
  } on DioError catch (e) {
    print("API Error: ${e.message}");
    throw ApiException("Failed to fetch lessons.");
  }
}


  Future<List<StudyMaterial>> getStudyMaterialOfTopic({
    required int lessonId,
    required int topicId,
    required bool useParentApi,
    required int childId,
  }) async {
    try {
      // Log input parameters
      print("Fetching study materials with:");
      print("  lessonId: $lessonId");
      print("  topicId: $topicId");
      print("  childId: $childId");
      print("  useParentApi: $useParentApi");

      Map<String, dynamic> queryParameters = {
        "topic_id": topicId,
        "lesson_id": lessonId,
      };

      if (useParentApi) {
        queryParameters["child_id"] = childId;
      }

      // Log query parameters
      print("Query Parameters: $queryParameters");

      final result = await Api.get(
        url: useParentApi
            ? Api.getstudyMaterialsOfTopicParent
            : Api.getstudyMaterialsOfTopic,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      // Log API response
      print("API Response: ${result}");

      final studyMaterialJson = result['data'] as List;
      final files = (studyMaterialJson.first['file'] ?? []) as List;

      return files
          .map((file) => StudyMaterial.fromJson(Map.from(file)))
          .toList();
    } on DioError catch (e) {
      _logError(e);
      throw ApiException("Failed to fetch study materials. ${e.response?.data}");
    }
  }

  void _logError(DioError e) {
    // Log error details
    print("API Error: ${e.message}");
    if (e.response != null) {
      print("Response Status: ${e.response?.statusCode}");
      print("Response Data: ${e.response?.data}");
      print("Response Headers: ${e.response?.headers}");
    } else {
      print("Request Error: ${e.requestOptions}");
    }
  }

  Future<void> downloadStudyMaterialFile({
    required String url,
    required String savePath,
    required CancelToken cancelToken,
    required Function updateDownloadedPercentage,
  }) async {
    try {
      // Log download parameters
      print("Starting download:");
      print("  URL: $url");
      print("  Save Path: $savePath");

      await Api.download(
        cancelToken: cancelToken,
        url: url,
        savePath: savePath,
        updateDownloadedPercentage: updateDownloadedPercentage,
      );

      print("Download completed for: $url");
    } catch (e) {
      print("Download Error: ${e.toString()}");
      throw ApiException(e.toString());
    }
  }
}
