import 'package:app/blocs/blocs.dart';
import 'package:app/models/models.dart';
import 'package:app/themes/theme.dart';
import 'package:app/utils/utils.dart';
import 'package:app/widgets/widgets.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InsightContainer extends StatelessWidget {
  const InsightContainer(this.insight, {super.key});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: insight.isAvailable
            ? insight.airQuality.color.withOpacity(0.2)
            : CustomColors.greyColor.withOpacity(0.2),
        borderRadius: const BorderRadius.all(
          Radius.circular(16.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  insight.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CustomTextStyle.headline8(context),
                ),
                const SizedBox(
                  height: 7,
                ),
                Visibility(
                  visible: insight.isAvailable,
                  child: AutoSizeText(
                    insight.airQuality.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTextStyle.headline8(context),
                  ),
                ),
                Visibility(
                  visible: !insight.isAvailable,
                  child: AutoSizeText(
                    'No air quality data available',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTextStyle.headline8(context),
                  ),
                ),
              ],
            ),
          ),
          SvgIcons.airQualityEmoji(
            insight.airQuality,
            height: 38,
            width: 48,
            isEmpty: !insight.isAvailable,
          ),
        ],
      ),
    );
  }
}

class InsightsDayReading extends StatelessWidget {
  const InsightsDayReading(
    this.insight, {
    super.key,
    required this.isActive,
  });
  final Insight insight;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    Color color = insight.isAvailable
        ? CustomColors.appColorBlack
        : CustomColors.greyColor;

    return InkWell(
      onTap: () => context.read<InsightsBloc>().add(SwitchInsight(insight)),
      child: SizedBox(
        height: 73,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isActive ? CustomColors.appColorBlue : Colors.transparent,
                borderRadius: const BorderRadius.all(
                  Radius.circular(25.0),
                ),
              ),
              child: Center(
                child: Text(
                  insight.dateTime.getWeekday().characters.first.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? Colors.white : color,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              '${insight.dateTime.day}',
              style: TextStyle(
                color: color,
              ),
            ),
            const Spacer(),
            SvgIcons.airQualityEmoji(
              insight.airQuality,
              isEmpty: !insight.isAvailable,
            ),
          ],
        ),
      ),
    );
  }
}

class InsightsCalendar extends StatelessWidget {
  const InsightsCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsBloc, InsightsState>(
      builder: (context, state) {
        Insight? selectedInsight = state.selectedInsight;
        if (selectedInsight == null) {
          return Container();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(16.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: state.insights
                        .map(
                          (e) => InsightsDayReading(
                            e,
                            isActive: e == selectedInsight,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(
                  height: 21,
                ),
                InsightContainer(selectedInsight),
                const SizedBox(
                  height: 21,
                ),
                InkWell(
                  onTap: () async {
                    if (selectedInsight.isAvailable) {
                      await airQualityInfoDialog(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: !selectedInsight.isAvailable,
                          child: Expanded(
                            child: AutoSizeText(
                              'We’re having issues with our network no worries, we’ll be back up soon.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  CustomTextStyle.bodyText4(context)?.copyWith(
                                color:
                                    CustomColors.appColorBlack.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: selectedInsight.isAvailable,
                          child: Expanded(
                            child: AutoSizeText(
                              selectedInsight.airQualityMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  CustomTextStyle.bodyText4(context)?.copyWith(
                                color:
                                    CustomColors.appColorBlack.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: selectedInsight.isAvailable,
                          child: SvgIcons.information(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ForecastContainer extends StatelessWidget {
  const ForecastContainer(this.insight, {super.key});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    if (insight.forecastMessage.isEmpty) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Container(),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 36,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Text(
              'Forecast',
              style: CustomTextStyle.headline8(context)?.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              height: 64,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(16.0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AutoSizeText(
                      insight.forecastMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CustomTextStyle.bodyText4(context)?.copyWith(
                        color: CustomColors.appColorBlack.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HealthTipsWidget extends StatelessWidget {
  const HealthTipsWidget(this.insight, {super.key});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    if (insight.healthTips.isEmpty) {
      return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250), child: Container());
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          const SizedBox(
            height: 32,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              insight.healthTipsTitle(),
              textAlign: TextAlign.left,
              style: CustomTextStyle.headline7(context),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            height: 128,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 12.0 : 6.0,
                    right:
                        index == (insight.healthTips.length - 1) ? 12.0 : 6.0,
                  ),
                  child: HealthTipContainer(insight.healthTips[index]),
                );
              },
              itemCount: insight.healthTips.length,
            ),
          ),
        ],
      ),
    );
  }
}
