/// The current stage of loading, answering, or submitting a survey.
enum SurveyViewState {
  /// Survey data is being loaded.
  loading,

  /// The requested survey could not be found.
  notFound,

  /// The form is ready for answers.
  ready,

  /// The main survey response is being submitted.
  submitting,

  /// The survey flow has finished successfully.
  completed,

  /// An error prevents the survey from being displayed.
  error,
}
