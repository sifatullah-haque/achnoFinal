// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Achno';

  @override
  String get hello => 'Bonjour le monde';

  @override
  String get settings => 'Paramètres';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get language => 'Langue';

  @override
  String get english => 'Anglais';

  @override
  String get arabic => 'Arabe';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Spanish';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsAll => 'Tous';

  @override
  String get notificationsMessages => 'Messages';

  @override
  String get notificationsActivity => 'Activité';

  @override
  String get notificationsSystem => 'Système';

  @override
  String get notificationEmpty => 'Pas de notifications';

  @override
  String get notificationEmptyMessage => 'Vous êtes à jour !';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get markAsUnread => 'Marquer comme non lu';

  @override
  String get deleteNotification => 'Supprimer la notification';

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get markAllAsRead => 'Tout marquer comme lu';

  @override
  String get clearAllNotifications => 'Effacer toutes les notifications';

  @override
  String get clearAllConfirmation =>
      'Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cette action ne peut pas être annulée.';

  @override
  String get cancel => 'Annuler';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get notificationSettings => 'Paramètres de notification';

  @override
  String get follow => 'Suivre';

  @override
  String get messages => 'Messages';

  @override
  String get search => 'Rechercher';

  @override
  String get noMessages => 'Pas encore de messages';

  @override
  String get startConversation => 'Commencer une conversation avec quelqu\'un';

  @override
  String get newMessage => 'Nouveau Message';

  @override
  String get addPost => 'Ajouter un post';

  @override
  String get messageHint => 'Écrivez votre message...';

  @override
  String get cityHint => 'Sélectionner la ville';

  @override
  String get activityLabel => 'Activité';

  @override
  String get recordVoice => 'Enregistrer un message vocal';

  @override
  String get postButtonLabel => 'Publier';

  @override
  String get errorSharingPost => 'Échec du partage de la publication';

  @override
  String get errorLikePost => 'Échec de la mise à jour du j\'aime';

  @override
  String get activeFilters => 'Filtres actifs';

  @override
  String messageToUser(String userName) {
    return 'Message à $userName';
  }

  @override
  String get typeYourMessage => 'Tapez votre message';

  @override
  String get send => 'Envoyer';

  @override
  String get messageSent => 'Message envoyé avec succès';

  @override
  String get respond => 'Répondre';

  @override
  String get share => 'Partager';

  @override
  String get message => 'Message';

  @override
  String get responses => 'réponses';

  @override
  String get filters => 'Filtres';

  @override
  String get postType => 'Type de publication';

  @override
  String get request => 'Demande';

  @override
  String get offer => 'Offre';

  @override
  String get city => 'Ville';

  @override
  String get activity => 'Activité';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get apply => 'Appliquer';

  @override
  String get noPosts => 'Aucune publication disponible';

  @override
  String get createFirstPost => 'Soyez le premier à créer une publication !';

  @override
  String get errorLoadingPosts => 'Erreur lors du chargement des publications';

  @override
  String get pleaseRetry => 'Veuillez réessayer plus tard';

  @override
  String get retry => 'Réessayer';

  @override
  String get noMatchingResults => 'Aucun résultat correspondant';

  @override
  String get tryDifferentFilters => 'Essayez différentes options de filtrage';

  @override
  String get playingAudioMessage => 'Lecture du message audio...';

  @override
  String get tapToPlayAudio => 'Appuyez pour lire le message audio';

  @override
  String get distance => 'Distance';

  @override
  String get whatAreYouLookingFor => 'Que recherchez-vous ?';

  @override
  String yourLocation(String location) {
    return 'Votre emplacement : $location';
  }

  @override
  String get all => 'Tous';

  @override
  String get woodWorker => 'Menuisier';

  @override
  String get locationServicesDisabled =>
      'Les services de localisation sont désactivés';

  @override
  String get locationPermissionDenied => 'Autorisation de localisation refusée';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'Les autorisations de localisation sont définitivement refusées';

  @override
  String get failedToGetLocation => 'Échec de l\'obtention de la localisation';

  @override
  String get gotLocation => 'Localisation obtenue';

  @override
  String get cannotPrecalculateDistances =>
      'Impossible de précalculer les distances - la ville d\'origine de l\'utilisateur n\'est pas disponible';

  @override
  String get userHomeCityFetched =>
      'Ville d\'origine de l\'utilisateur récupérée';

  @override
  String kmDistance(int distance) {
    return '$distance km';
  }

  @override
  String waitingForLocation(int distance) {
    return '${distance}km (en attente de localisation...)';
  }

  @override
  String get selectCity => 'Sélectionner la ville';

  @override
  String get password => 'Mot de passe';

  @override
  String get pleaseEnterPassword => 'Veuillez saisir un mot de passe';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get fullName => 'Nom complet';

  @override
  String get pleaseEnterName => 'Veuillez saisir votre nom complet';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get pleaseEnterPhone => 'Veuillez saisir votre numéro de téléphone';

  @override
  String get invalidPhoneNumber =>
      'Veuillez saisir un numéro de téléphone valide';

  @override
  String get preferredLanguage => 'Langue préférée';

  @override
  String get iAm => 'Je suis un(e):';

  @override
  String get client => 'Client';

  @override
  String get professional => 'Professionnel';

  @override
  String get chooseProfession => 'Choisissez votre profession:';

  @override
  String get selectOtherActivity => 'Sélectionner une autre activité';

  @override
  String get completeRegistration => 'Terminer l\'inscription';

  @override
  String get continue_ => 'Continuer';

  @override
  String get alreadyMember => 'Déjà membre?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get success => 'Succès !';

  @override
  String get accountCreated => 'Compte créé avec succès';

  @override
  String get continueToApp => 'Continuer vers l\'application';

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get textBio => 'Biographie Textuelle (Optionnel)';

  @override
  String get audioBio => 'Biographie Audio';

  @override
  String get recordAudioBio => 'Enregistrer une Biographie Audio';

  @override
  String get audioBioAvailable => 'Biographie Audio Disponible';

  @override
  String get recordNewAudio => 'Enregistrer un Nouveau Audio';

  @override
  String get audioBioDescription =>
      'Enregistrez une courte biographie audio (jusqu\'à 30 secondes)';

  @override
  String recording(String duration) {
    return 'Enregistrement: $duration';
  }

  @override
  String get stopRecording => 'Arrêter l\'Enregistrement';

  @override
  String get phoneCannotBeChanged =>
      'Le numéro de téléphone ne peut pas être modifié';

  @override
  String get phone => 'Téléphone';

  @override
  String get professionalActivity => 'Votre Activité Professionnelle';

  @override
  String get selectImageSource => 'Sélectionner la Source de l\'Image';

  @override
  String get camera => 'Caméra';

  @override
  String get gallery => 'Galerie';

  @override
  String get permissionRequired => 'Autorisation Requise';

  @override
  String get mediaPermissionMessage =>
      'Cette fonctionnalité nécessite l\'autorisation d\'accéder à vos médias. Veuillez l\'activer dans les paramètres de l\'application.';

  @override
  String get openSettings => 'Ouvrir les Paramètres';

  @override
  String get saveChanges => 'Enregistrer les Modifications';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès';

  @override
  String get pleaseEnterCity => 'Veuillez saisir votre ville';

  @override
  String get postDuration => 'Durée de publication';

  @override
  String get unlimited => 'Illimité';

  @override
  String get hours48 => '48 heures';

  @override
  String get days7 => '7 jours';

  @override
  String get days30 => '30 jours';

  @override
  String get maxOneMinute => 'Max 1 minute';

  @override
  String get allowMicPermission => 'Autoriser';

  @override
  String get microphoneAccessNeeded => 'Accès au microphone nécessaire';

  @override
  String get failedToInitializeRecorder =>
      'Échec de l\'initialisation de l\'enregistreur';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get tapToRecord => 'Appuyez pour enregistrer';

  @override
  String get tapToStop => 'Appuyez pour arrêter';

  @override
  String get audioRecording => 'Enregistrement audio';

  @override
  String get otherActivities => 'Autres activités';

  @override
  String get typeToSearch => 'Tapez pour rechercher';

  @override
  String get cityRequired => 'Ville requise';

  @override
  String get addOptionalDetails =>
      'Ajouter des détails optionnels (non requis)';

  @override
  String get postSuccessfullySubmitted => 'Publication soumise avec succès';

  @override
  String get postSubmittedAwaitingApproval =>
      'Votre publication a été soumise et attend l\'approbation de l\'administrateur. Elle apparaîtra sur la page d\'accueil une fois approuvée.';

  @override
  String get maximumRecordingTimeReached =>
      'Durée d\'enregistrement maximale de 1 minute atteinte.';

  @override
  String get textOrVoiceRequired =>
      'Veuillez fournir un message texte ou vocal';

  @override
  String get mustBeLoggedIn => 'Vous devez être connecté pour publier';

  @override
  String get microphonePermissionRequired =>
      'L\'autorisation du microphone est requise pour les messages vocaux';

  @override
  String get failedToCreatePost => 'Échec de la création de la publication';

  @override
  String get audioFileTooLarge =>
      'Fichier audio trop volumineux. Veuillez enregistrer un message plus court.';

  @override
  String get bothPermissionsRequired =>
      'Les autorisations microphone et stockage sont toutes deux requises';

  @override
  String get failedToInitializeRecording =>
      'Échec de l\'initialisation de l\'enregistrement';

  @override
  String get failedToStartRecording =>
      'Échec du démarrage de l\'enregistrement';

  @override
  String get failedToStopRecording => 'Échec de l\'arrêt de l\'enregistrement';

  @override
  String get failedToPlayRecording =>
      'Échec de la lecture de l\'enregistrement';

  @override
  String get voiceRecorderNotInitialized =>
      'L\'enregistreur vocal n\'est pas initialisé. Veuillez vérifier les autorisations du microphone.';

  @override
  String get failedToLoadProfileData =>
      'Échec du chargement des données de profil';

  @override
  String get placeSearchFailed => 'Échec de la recherche de lieu';

  @override
  String get failedToSearchPlaces => 'Échec de la recherche de lieux';

  @override
  String get plumber => 'Plombier';

  @override
  String get electrician => 'Électricien';

  @override
  String get painter => 'Peintre';

  @override
  String get carpenter => 'Charpentier';

  @override
  String get mason => 'Maçon';

  @override
  String get tiler => 'Carreleur';

  @override
  String get gardener => 'Jardinier';

  @override
  String get cleaner => 'Nettoyeur';

  @override
  String get roofer => 'Couvreur';

  @override
  String get welder => 'Soudeur';

  @override
  String get windowInstaller => 'Installateur de fenêtres';

  @override
  String get hvacTechnician => 'Technicien CVC';

  @override
  String get flooringInstaller => 'Installateur de sols';

  @override
  String get landscaper => 'Paysagiste';

  @override
  String get other => 'Autre';

  @override
  String get loadingMessages => 'Chargement des messages...';

  @override
  String get typeAMessage => 'Tapez un message...';

  @override
  String get recordingAudio => 'Enregistrement audio...';

  @override
  String get audioReadyToSend => 'Audio prêt à envoyer';

  @override
  String get sendingAudio => 'Envoi de l\'audio...';

  @override
  String get sendingImage => 'Envoi de l\'image...';

  @override
  String get audioMessage => 'Message audio';

  @override
  String get image => 'Image';

  @override
  String get failedToLoadImage => 'Échec du chargement de l\'image';

  @override
  String get cannotSendMessage =>
      'Impossible d\'envoyer le message : Conversation invalide';

  @override
  String get cannotSendImage =>
      'Impossible d\'envoyer l\'image : Conversation invalide';

  @override
  String get errorSendingMessage => 'Erreur lors de l\'envoi du message';

  @override
  String get errorSendingAudio => 'Erreur lors de l\'envoi du message audio';

  @override
  String get errorSelectingImage => 'Erreur lors de la sélection de l\'image';

  @override
  String get errorSendingImage => 'Erreur lors de l\'envoi de l\'image';

  @override
  String get cannotViewProfile =>
      'Impossible de voir le profil : ID utilisateur non disponible';

  @override
  String get couldNotOpenConversation => 'Impossible d\'ouvrir la conversation';

  @override
  String get errorLoadingConversations =>
      'Erreur lors du chargement des conversations. Veuillez réessayer.';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get user => 'Utilisateur';

  @override
  String get viewRelatedPost => 'Voir la publication associée';

  @override
  String get clearChat => 'Effacer la discussion';

  @override
  String get clearChatConfirmation =>
      'Êtes-vous sûr de vouloir effacer cette discussion ? Cette action ne peut pas être annulée.';

  @override
  String requestWithActivity(String activity) {
    return 'Demande : $activity';
  }

  @override
  String offerWithActivity(String activity) {
    return 'Offre : $activity';
  }

  @override
  String get viewPost => 'Voir la publication';

  @override
  String get messageLabel => 'Message :';

  @override
  String get audioMessageLabel => 'Message audio :';

  @override
  String get close => 'Fermer';

  @override
  String get like => 'J\'aime';

  @override
  String get comment => 'Commentaire';

  @override
  String get mention => 'Mention';

  @override
  String get system => 'Système';

  @override
  String get sendTestNotification => 'Envoyer une notification de test';

  @override
  String get sendingTestNotification => 'Envoi de la notification de test...';

  @override
  String get testNotificationSent =>
      'Notification de test envoyée ! Vérifiez votre panneau de notifications.';

  @override
  String get failedToSendTestNotification =>
      'Échec de l\'envoi de la notification de test';

  @override
  String get failedToLoadNotifications =>
      'Échec du chargement des notifications';

  @override
  String get posts => 'Publications';

  @override
  String get followers => 'Abonnés';

  @override
  String get following => 'Abonnements';

  @override
  String get reviews => 'Avis';

  @override
  String get bio => 'Biographie';

  @override
  String get voiceBio => 'Bio Vocale';

  @override
  String get noPostsYet => 'Aucune publication pour le moment';

  @override
  String get shareFirstPost =>
      'Partagez votre première publication avec la communauté';

  @override
  String get userHasNoPosts => 'Cet utilisateur n\'a encore rien publié';

  @override
  String get createPost => 'Créer une Publication';

  @override
  String get noReviewsYet => 'Aucun avis pour le moment';

  @override
  String get noReviewsReceived => 'Vous n\'avez encore reçu aucun avis';

  @override
  String get userHasNoReviews => 'Cet utilisateur n\'a encore reçu aucun avis';

  @override
  String get logout => 'Déconnexion';

  @override
  String get areYouSureLogout => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get adminDashboard => 'Tableau de Bord Admin';

  @override
  String get pending => 'En attente';

  @override
  String get approved => 'Approuvés';

  @override
  String get rejected => 'Rejetés';

  @override
  String get noPendingPostsToReview =>
      'Aucune publication en attente de révision';

  @override
  String get noApprovedPosts => 'Aucune publication approuvée';

  @override
  String get noRejectedPosts => 'Aucune publication rejetée';

  @override
  String get refresh => 'Actualiser';

  @override
  String get approve => 'Approuver';

  @override
  String get reject => 'Rejeter';

  @override
  String get moveToApproved => 'Déplacer vers Approuvés';

  @override
  String get moveToRejected => 'Déplacer vers Rejetés';

  @override
  String get postApprovedSuccess =>
      'Publication approuvée et maintenant visible sur la page d\'accueil';

  @override
  String get postRejectedSuccess =>
      'Publication rejetée et supprimée de la page d\'accueil';

  @override
  String get errorApprovingPost =>
      'Erreur lors de l\'approbation de la publication';

  @override
  String get errorRejectingPost => 'Erreur lors du rejet de la publication';

  @override
  String get voiceMessage => 'Message vocal';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int minutes) {
    return 'Il y a ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'Il y a ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'Il y a ${days}j';
  }

  @override
  String get you => 'Vous';

  @override
  String get voiceReview => 'Avis Vocal';

  @override
  String duration(String duration) {
    return 'Durée: $duration';
  }

  @override
  String reviewsCount(int count) {
    return '$count avis';
  }

  @override
  String get unknownDate => 'Date inconnue';

  @override
  String get anonymous => 'Anonyme';

  @override
  String get unknownUser => 'Utilisateur Inconnu';

  @override
  String get blockUser => 'Bloquer l\'utilisateur';

  @override
  String get reportUser => 'Signaler l\'utilisateur';

  @override
  String get shareProfile => 'Partager le profil';
}
