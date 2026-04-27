// lib/widgets/ai_suggestion_panel.dart
import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AISuggestionPanel extends StatelessWidget {
  final AIAnalysisResult? analysis;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AISuggestionPanel({
    Key? key,
    this.analysis,
    this.isLoading = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (analysis == null) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildScoreIndicator(context),
            const SizedBox(height: 20),
            if (analysis!.hasCriticalIssues) _buildCriticalAlert(),
            _buildSuggestionsList(context),
            const SizedBox(height: 16),
            _buildInsightsRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'AI is analyzing your schedule...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.psychology, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'AI Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a schedule to see AI suggestions',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.psychology,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Schedule Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Generated ${_formatTimeAgo(analysis!.generatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Refresh Analysis',
        ),
      ],
    );
  }

  Widget _buildScoreIndicator(BuildContext context) {
    final score = analysis!.overallScore;
    final color = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Score',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${score.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Icon(
                  score >= 80 ? Icons.check_circle : score >= 60 ? Icons.warning : Icons.error,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${analysis!.criticalSuggestions.length} critical issue(s) require attention',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context) {
    if (!analysis!.hasSuggestions) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 12),
            Text(
              'No issues detected! Schedule looks optimal.',
              style: TextStyle(color: Colors.green[700]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions (${analysis!.suggestions.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...analysis!.suggestions.take(5).map((s) => _buildSuggestionItem(context, s)),
        if (analysis!.suggestions.length > 5)
          TextButton(
            onPressed: () {
              // TODO: Show all suggestions in a dialog
            },
            child: Text('View ${analysis!.suggestions.length - 5} more'),
          ),
      ],
    );
  }

  Widget _buildSuggestionItem(BuildContext context, AISuggestion suggestion) {
    final priorityColor = _getPriorityColor(suggestion.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  suggestion.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              const Spacer(),
              _getTypeIcon(suggestion.type),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.description,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 14, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.action,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: analysis!.insights.map((insight) {
        final color = insight.trend.contains('good') || insight.trend.contains('optimal')
            ? Colors.green
            : insight.trend.contains('warning') || insight.trend.contains('underutilized')
            ? Colors.orange
            : Colors.red;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                insight.category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                insight.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getPriorityColor(AIPriority priority) {
    switch (priority) {
      case AIPriority.critical: return Colors.red;
      case AIPriority.high: return Colors.orange;
      case AIPriority.medium: return Colors.blue;
      case AIPriority.low: return Colors.green;
    }
  }

  Icon _getTypeIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.workload:
        return Icon(Icons.work, size: 16, color: Colors.blue[400]);
      case SuggestionType.roomUtilization:
        return Icon(Icons.meeting_room, size: 16, color: Colors.purple[400]);
      case SuggestionType.teacherWellness:
        return Icon(Icons.favorite, size: 16, color: Colors.red[400]);
      case SuggestionType.conflictPrevention:
        return Icon(Icons.warning, size: 16, color: Colors.orange[400]);
      case SuggestionType.optimization:
        return Icon(Icons.trending_up, size: 16, color: Colors.green[400]);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}