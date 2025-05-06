// lib/widgets/share_modal.dart

import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:share_plus/share_plus.dart';  // 혹은 `share`

class ShareModal extends StatelessWidget {
  final String placeName;
  final String placeId;
  final String videoId;
  final String source;

  const ShareModal({
    super.key,
    required this.placeName,
    required this.placeId,
    required this.videoId,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      expand: false,
      builder: (context, scrollController) => SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShareOption(
                  label: '영상 공유하기',
                  onTap: () {
                    Navigator.pop(context);
                    FirebaseAnalytics.instance.logShare(
                      contentType: "video",
                      itemId: videoId,
                      method: '${source}VideoShare',
                    );
                    Share.share(
                      'https://www.youtube.com/shorts/$videoId',
                      subject: placeName,
                    );
                  },
                ),
                _ShareOption(
                  label: '지도 공유하기',
                  onTap: () {
                    Navigator.pop(context);
                    FirebaseAnalytics.instance.logShare(
                      contentType: "map",
                      itemId: videoId,
                      method: '${source}MapShare',
                    );

                    /// TODO: 네이버 지도로 변경하기

                    Share.share(
                      'https://www.google.com/maps/search/?api=1&query=$placeName&query_place_id=$placeId',
                      subject: placeName,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
