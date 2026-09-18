import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_admin_shell.dart';
import '../../../../core/widgets/hux_states.dart';
import '../capsules/survey_list_capsule.dart';
import '../widgets/project_form.dart';

/// The screen for creating a project or editing its locale and domain settings.
class ProjectEditorPage extends RearchConsumer {
  /// The identifier of the project containing the survey.
  final int? projectId;

  /// Creates ProjectEditorPage with the supplied values.
  const ProjectEditorPage({super.key, this.projectId});

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context, use) {
    final manager = use(surveyListCapsule);
    final client = use(clientCapsule);
    final role = client.auth.signedInUser?.role;
    final canManageUsers = role == AdminRole.admin;
    final isNew = projectId == null;
    final (project, setProject) = use.state<Project?>(null);
    final (isLoading, setLoading) = use.state(!isNew);
    final (isSaving, setSaving) = use.state(false);
    final (error, setError) = use.state<String?>(null);

    if (use.isFirstBuild() && projectId != null) {
      manager.getProject(projectId!).then((loaded) {
        setProject(loaded?.project);
        setLoading(false);
      });
    }

    Widget child;
    if (isLoading) {
      child = HuxLoadingState(
        message: context.tr('Loading...'),
        maxWidth: 720,
      );
    } else if (!isNew && project == null) {
      child = HuxPageBody(
        child: HuxErrorState(
          message: context.tr('Project not found'),
          onRetry: () => context.go('/admin'),
        ),
      );
    } else {
      child = HuxPageBody(
        maxWidth: 720,
        child: ProjectForm(
          key: ValueKey(project?.id ?? 'new-project'),
          existingProject: project,
          isSaving: isSaving,
          error: error ?? manager.state.error,
          onSave: (value) async {
            setSaving(true);
            setError(null);
            final saved = isNew
                ? await manager.createProject(value)
                : await manager.updateProject(value);
            setSaving(false);
            if (saved != null && context.mounted) {
              context.go('/admin');
            } else if (manager.state.error != null) {
              setError(manager.state.error);
            }
          },
        ),
      );
    }

    return HuxAdminShell(
      title: isNew ? context.tr('New Project') : context.tr('Project Settings'),
      selectedItemId: 'surveys',
      showUsers: canManageUsers,
      showSettings: canManageUsers,
      onBack: () => context.go('/admin'),
      actions: [],
      child: SafeArea(child: child),
    );
  }
}
