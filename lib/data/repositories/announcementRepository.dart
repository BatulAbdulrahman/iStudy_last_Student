import 'package:eschool/data/models/announcement.dart';
import 'package:eschool/utils/api.dart';
import 'package:flutter/foundation.dart';

class AnnouncementRepository {
  /// Fetch notice board details
  Future<Map<String, dynamic>> fetchAnnouncements({
    int? page,
    required bool useParentApi,
    required int childId,
    required bool isGeneralAnnouncement,
    int? classSubjectId,
  }) async {
    try {
      // Construct query parameters
      Map<String, dynamic> queryParameters = {
        if (page != null && page > 0) "page": page,
        "type": isGeneralAnnouncement ? "class" : "subject",
        if (!isGeneralAnnouncement && classSubjectId != null)
          "class_subject_id": classSubjectId,
      };

      // Add child ID if using parent API
      if (useParentApi) {
        queryParameters["child_id"] = childId;
      }

      if (kDebugMode) {
        print("Query Parameters: $queryParameters");
      }

      // Fetch data from API
      final result = await Api.get(
        url: useParentApi
            ? Api.generalAnnouncementsParent
            : Api.generalAnnouncements,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      if (result['data'] == null || result['data']['data'] == null) {
        throw ApiException("Invalid API response structure");
      }

      // Map the API result to the expected structure
      return {
        "announcements": (result['data']['data'] as List)
            .map((e) => Announcement.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        "totalPage": result['data']['last_page'] as int,
        "currentPage": result['data']['current_page'] as int,
      };
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching announcements: $e");
      }
      throw ApiException("Failed to fetch announcements: $e");
    }
  }
}
