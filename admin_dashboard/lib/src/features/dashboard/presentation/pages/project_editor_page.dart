import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/auth_state_capsule.dart';
import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_admin_shell.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';
import '../../../../core/widgets/hux_states.dart';
import '../capsules/survey_list_capsule.dart';
import '../widgets/project_form.dart';

class ProjectEditorPage extends RearchConsumer {
  final int? projectId;

  const ProjectEditorPage({super.key, this.projectId});

  @override
  Widget build(context, use) {
    final manager = use(surveyListCapsule);
    final authManager = use(authStateCapsule);
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
      actions: [
        HuxIconActionButton(
          onPressed: authManager.logout,
          icon: LucideIcons.logOut,
          tooltip: context.tr('Logout'),
          size: HuxButtonSize.medium,
        ),
      ],
      child: SafeArea(child: child),
    );
  }
}
