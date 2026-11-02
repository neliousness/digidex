import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/ad_config.dart';
import '../theme/comic.dart';
import '../theme/comic_widgets.dart';
import 'ad_service.dart';

enum BannerFrame {
  /// The 66px white bottom bar with a 5px ink top border.
  bottomBar,

  /// The grey rounded slot inside the detail page.
  inline,
}

/// A standard 320×50 banner in the comic frame. It takes no space until an ad
/// has loaded, so a missing ad (no fill, offline, unsupported platform)
/// changes nothing.
class BannerAdSlot extends StatefulWidget {
  final BannerFrame frame;

  /// Space above the ad, only while one is shown (so no ad leaves no gap).
  final double gapAbove;

  const BannerAdSlot({super.key, this.frame = BannerFrame.bottomBar, this.gapAbove = 0});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested && AdConfig.supported) {
      _requested = true;
      _load(context.read<AdService>());
    }
  }

  Future<void> _load(AdService ads) async {
    if (!await ads.ready || !mounted) return;
    final banner = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _banner = null);
        },
      ),
    );
    _banner = banner;
    banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    Widget content;
    if (banner == null || !_loaded) {
      content = const SizedBox(width: double.infinity);
    } else {
      final ad = SizedBox(width: banner.size.width.toDouble(), height: banner.size.height.toDouble(), child: AdWidget(ad: banner));
      content = widget.frame == BannerFrame.bottomBar
          ? AdBar(child: ad)
          : Container(
              margin: EdgeInsets.only(top: widget.gapAbove),
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Comic.adGrey, borderRadius: BorderRadius.circular(14), border: Border.all(color: Comic.ink, width: 3)),
              child: ad,
            );
    }
    return AnimatedSize(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, child: content);
  }
}
