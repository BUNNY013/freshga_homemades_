import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/following_provider.dart';
import '../../widgets/following/feed_card.dart';
import '../../widgets/following/feed_shimmer.dart';
import '../../widgets/following/following_filter_chips.dart';
import '../../widgets/following/following_empty_state.dart';
import '../../widgets/following/following_store_list.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowingProvider>().initialize();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final provider = context.read<FollowingProvider>();
        if (!provider.isPaginating && provider.hasMore) {
          provider.fetchFeed(refresh: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<FollowingProvider>().fetchFeed(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'following.title'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<FollowingProvider>(
        builder: (context, provider, child) {
          if (!provider.isLoadingIds && provider.followingStoreIds.isEmpty) {
            return const FollowingEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primaryGreen,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [FollowingStoreList(), FollowingFilterChips()],
                  ),
                ),
                if (provider.isLoading || provider.isLoadingIds)
                  const SliverToBoxAdapter(child: FeedShimmer())
                else if (provider.feed.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyFeedFilter(provider.selectedFilter),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      100,
                    ), // Bottom padding for cart
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == provider.feed.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryGreen,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final update = provider.feed[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: FeedCard(update: update),
                          );
                        },
                        childCount:
                            provider.feed.length +
                            (provider.isPaginating ? 1 : 0),
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

  Widget _buildEmptyFeedFilter(String filter) {
    String message = "No updates found.";
    if (filter == 'new_launch') message = "No new launches recently.";
    if (filter == 'restock') message = "No restocks recently.";
    if (filter == 'offer') message = "No offers currently available.";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
