import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../common/colors.dart';

class TokenStepper extends StatelessWidget {
  final String doctorId;
  final String clinicId;
  final String date;

  const TokenStepper({
    super.key,
    required this.doctorId,
    required this.clinicId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final behaviorDocRef = FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicId)
        .collection('doctors')
        .doc(doctorId)
        .collection('doctorBehaviour')
        .doc(date);


    return StreamBuilder<DocumentSnapshot>(
      stream: behaviorDocRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }
        final data = Map<String, dynamic>.from(snapshot.data!.data() as Map);
        final tokens = List<Map<String, dynamic>>.from(data['tokens'] ?? []);

        if (tokens.isEmpty) return const SizedBox();

        // Step 1: Build the ordered list of called tokens (with their maps)
        final List<String> calledTokens =
        tokens.map((e) => e['tokenNumber'] as String).toList();

        // Step 2: Build a map of prefix -> all numbers called for that prefix
        final Map<String, Set<int>> calledNumbersByPrefix = {};
        for (var t in calledTokens) {
          final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(t);
          if (match != null) {
            String prefix = match.group(1)!;
            int num = int.parse(match.group(2)!);
            calledNumbersByPrefix.putIfAbsent(prefix, () => <int>{}).add(num);
          }
        }

        // Step 3: For each prefix, find the min and max number
        final Map<String, int> minByPrefix = {};
        final Map<String, int> maxByPrefix = {};
        calledNumbersByPrefix.forEach((prefix, nums) {
          minByPrefix[prefix] = nums.reduce((a, b) => a < b ? a : b);
          maxByPrefix[prefix] = nums.reduce((a, b) => a > b ? a : b);
        });

        // Step 4: Build the full step list, in the order of the tokens array, filling skipped tokens in the right place
        List<String> stepTokens = [];
        for (int i = 0; i < calledTokens.length; i++) {
          String curr = calledTokens[i];
          final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(curr);
          if (match == null) continue;
          String currPrefix = match.group(1)!;
          int currNum = int.parse(match.group(2)!);

          // Always add the current token
          if (!stepTokens.contains(curr)) stepTokens.add(curr);

          // If there's a next token, fill in any missing tokens between curr and next (of the same prefix)
          if (i < calledTokens.length - 1) {
            String next = calledTokens[i + 1];
            final nextMatch = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(next);
            if (nextMatch != null) {
              String nextPrefix = nextMatch.group(1)!;
              int nextNum = int.parse(nextMatch.group(2)!);

              if (currPrefix == nextPrefix && nextNum - currNum > 1) {
                // Fill in missing numbers for this prefix
                for (int n = currNum + 1; n < nextNum; n++) {
                  String skippedToken = '$currPrefix$n';
                  if (!stepTokens.contains(skippedToken)) stepTokens.add(skippedToken);
                }
              }
            }
          }
        }

        // Also, for each prefix, fill in any skipped tokens up to the max number for that prefix
        calledNumbersByPrefix.forEach((prefix, nums) {
          int minNum = minByPrefix[prefix]!;
          int maxNum = maxByPrefix[prefix]!;
          for (int n = minNum; n <= maxNum; n++) {
            String token = '$prefix$n';
            if (!stepTokens.contains(token)) stepTokens.add(token);
          }
        });

        // Step 5: Mark skipped tokens (in stepTokens but not in calledTokens, and before the current)
        String currentToken = calledTokens.isNotEmpty ? calledTokens.last : '';
        int currentIndex = stepTokens.indexOf(currentToken);

        Set<String> skippedTokens = {};
        for (int i = 0; i < stepTokens.length; i++) {
          final token = stepTokens[i];
          if (!calledTokens.contains(token) && i <= currentIndex) {
            skippedTokens.add(token);
          }
        }

        return Expanded(
          child: EasyStepper(
            activeStep: currentIndex,
            stepRadius: 36,
            stepBorderRadius: 0,
            borderThickness: 0,
            showLoadingAnimation: false,
            lineStyle: const LineStyle(
              lineLength: 38,
              lineType: LineType.dotted,
              defaultLineColor: Colors.white,
            ),
            showStepBorder: false,
            internalPadding: 0,
            steps: List.generate(stepTokens.length, (index) {
              final token = stepTokens[index];
              final isSkipped = skippedTokens.contains(token);
              final isActive = token == currentToken;
              final isPast = index < currentIndex && !isSkipped;
              final tooltipController = SuperTooltipController();
              return EasyStep(
                customStep: GestureDetector(
                  onTap: () async {
                    await tooltipController.showTooltip();
                  },
                  child: SuperTooltip(
                    content: Text( isSkipped
                        ? 'Skipped Token'
                        : isActive
                        ? 'Current Token'
                        : isPast
                        ? 'Passed Token'
                        : 'Upcoming Token',
                      style: TextStyle(
                        fontFamily: 'nunito',
                        fontWeight: FontWeight.bold,
                        color: isSkipped ? Colors.red : AppColors.lightpacha,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    borderColor: AppColors.lightpacha,
                    controller: tooltipController,
                    onShow: () async {
                      await Future.delayed(const Duration(seconds: 4));
                      tooltipController.hideTooltip();
                    },
                    showBarrier: false,
                    borderWidth: 0,
                    hasShadow: false,
                    hideTooltipOnBarrierTap: true,
                    child: Opacity(
                      opacity: isPast ? 0.8 : 1.0,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isSkipped
                              ? Colors.redAccent
                              : isActive
                              ? Colors.white
                              : Colors.white,
                          border: Border.all(
                            color: const Color(0xFFBFF264),
                            width: 6,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isActive || isSkipped)
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            token,
                            style: TextStyle(
                              color: isSkipped
                                  ? Colors.white
                                  : isActive
                                  ? AppColors.lightpacha
                                  : const Color(0xFFBFF264),
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.06,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, double screenWidth) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      children: [
        Text(
          "$label:\t ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: screenWidth * 0.04,
          ),
        ),
        Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.lightpacha,
                fontSize: screenWidth * 0.04,
              ),
            )),
      ],
    ),
  );
}

String formatTimeTo12Hour(String time24) {
  final dt = DateFormat("HH:mm:ss").parse(time24);
  return DateFormat("h:mm:ss a").format(dt);
}