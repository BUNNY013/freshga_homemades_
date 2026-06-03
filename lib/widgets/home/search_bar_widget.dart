import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../screens/search/search_screen.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final List<String> _searchHints = [
    "mango pickles...",
    "pure organic honey...",
    "fresh ground podis...",
    "authentic ghee sweets...",
    "healthy millet snacks...",
    "traditional savories...",
    "organic cold-pressed oils...",
    "natural health mixes...",
    "hand-ground spices...",
    "homemade papads...",
    "freshly baked cookies...",
    "premium dry fruits...",
    "homemade batter mixes..."
  ];
  
  int _currentIndex = 0;
  int _charIndex = 0;
  String _currentText = "";
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) return;

      final currentHint = _searchHints[_currentIndex];

      setState(() {
        if (_charIndex < currentHint.length) {
          _charIndex++;
          _currentText = currentHint.substring(0, _charIndex);
        } else {
          _typingTimer?.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _charIndex = 0;
                _currentText = "";
                _currentIndex = (_currentIndex + 1) % _searchHints.length;
              });
              _startTyping();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "$_currentText|",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mic_none_rounded, color: AppColors.primaryGreen, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
