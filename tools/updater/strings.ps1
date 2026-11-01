# Interface texts. English is the reference: a missing key falls back to it.
# Add a language by copying the "en" block. Saved as UTF-8 with BOM
# (PowerShell 5 reads accents wrong otherwise).

$script:Strings = @{
    en = @{
        title              = 'Project Updater'
        subtitle           = 'Clone, branches and add-ons, in one click.'
        state_repo         = 'Git repo  ·  branch {0}'
        state_detached     = 'Git repo  ·  detached HEAD'
        state_none         = 'No git yet  ·  will be linked to the remote'
        lbl_remote         = 'Remote URL'
        lbl_name           = 'Name'
        lbl_email          = 'Email'
        lbl_language       = 'Language'
        tip_remote         = "GitHub address of the project. Saved in tools/updater/updater.cfg,`nso a ZIP download of the project still knows where it comes from."
        tip_identity       = "Your git identity for commits (git config --global).`nGitHub sign-in is handled by Git Credential Manager: a browser window opens the first time."
        tip_update         = "Fetches every branch, fast-forwards what is behind, creates the missing local branches`nand installs the add-ons (submodules). Never discards local changes."
        btn_update         = 'Update project'
        btn_close          = 'Close'
        log_empty          = 'Press "Update project": each step is logged here.'
        step_init          = 'Linking this folder to {0}'
        step_fetch         = 'Fetching all branches'
        step_current       = 'Updating the current branch {0}'
        step_branches      = 'Creating the missing local branches'
        step_others        = 'Updating the other branches'
        step_submodules    = 'Installing the add-ons (submodules)'
        msg_uptodate       = '{0} is up to date'
        msg_ff             = '{0}: {1} new commit(s) pulled'
        msg_ahead          = '{0}: {1} local commit(s) not pushed yet'
        msg_diverged       = '{0} and {1} have both changed: left as is, merge by hand'
        msg_no_upstream    = '{0} has no remote branch: left as is'
        msg_ff_blocked     = '{0} not updated: local changes are in the way'
        msg_detached       = 'Detached HEAD: current branch not updated'
        msg_branch_created = 'Branch {0} created'
        msg_no_new_branch  = 'No new branch'
        msg_sub_ok         = '{0} ok'
        msg_sub_init       = '{0} installed'
        msg_sub_branch     = '{0} is on branch {1} with its own commits: left as is'
        msg_restored       = '{0} missing file(s) restored from {1}'
        msg_dirty          = '{0} file(s) with uncommitted changes (kept)'
        msg_identity_saved = 'Git identity saved'
        msg_tool_updated   = 'Project Updater updated to version {0}'
        msg_done           = 'Done: the project is ready to open in Godot.'
        msg_failed         = 'Stopped: {0}'
        err_no_git         = 'git.exe not found. Install Git for Windows or Fork, then try again.'
        err_no_remote      = 'No remote URL: paste the GitHub address of the project.'
        err_fetch          = 'the remote could not be reached (network, address or sign-in)'
        err_submodules     = 'some add-ons could not be installed'
    }
    fr = @{
        title              = 'Mise à jour du projet'
        subtitle           = 'Clone, branches et add-ons, en un clic.'
        state_repo         = 'Dépôt git  ·  branche {0}'
        state_detached     = 'Dépôt git  ·  HEAD détachée'
        state_none         = 'Pas encore de git  ·  sera relié au dépôt distant'
        lbl_remote         = 'Dépôt distant'
        lbl_name           = 'Nom'
        lbl_email          = 'E-mail'
        lbl_language       = 'Langue'
        tip_remote         = "Adresse GitHub du projet. Enregistrée dans tools/updater/updater.cfg,`npour qu'un ZIP du projet sache toujours d'où il vient."
        tip_identity       = "Ton identité git pour les commits (git config --global).`nLa connexion à GitHub passe par Git Credential Manager : une fenêtre s'ouvre la première fois."
        tip_update         = "Récupère toutes les branches, avance celles en retard, crée les branches locales manquantes`net installe les add-ons (sous-modules). Ne jette jamais de changement local."
        btn_update         = 'Mettre à jour'
        btn_close          = 'Fermer'
        log_empty          = 'Clique sur « Mettre à jour » : chaque étape s''affiche ici.'
        step_init          = 'Liaison de ce dossier à {0}'
        step_fetch         = 'Récupération de toutes les branches'
        step_current       = 'Mise à jour de la branche courante {0}'
        step_branches      = 'Création des branches locales manquantes'
        step_others        = 'Mise à jour des autres branches'
        step_submodules    = 'Installation des add-ons (sous-modules)'
        msg_uptodate       = '{0} est à jour'
        msg_ff             = '{0} : {1} nouveau(x) commit(s) récupéré(s)'
        msg_ahead          = '{0} : {1} commit(s) local(aux) pas encore poussé(s)'
        msg_diverged       = '{0} et {1} ont changé tous les deux : laissée telle quelle, à fusionner à la main'
        msg_no_upstream    = "{0} n'a pas de branche distante : laissée telle quelle"
        msg_ff_blocked     = '{0} pas mise à jour : des changements locaux bloquent'
        msg_detached       = 'HEAD détachée : branche courante pas mise à jour'
        msg_branch_created = 'Branche {0} créée'
        msg_no_new_branch  = 'Aucune nouvelle branche'
        msg_sub_ok         = '{0} ok'
        msg_sub_init       = '{0} installé'
        msg_sub_branch     = '{0} est sur la branche {1} avec ses propres commits : laissé tel quel'
        msg_restored       = '{0} fichier(s) manquant(s) restauré(s) depuis {1}'
        msg_dirty          = '{0} fichier(s) modifié(s) non commité(s) (gardés)'
        msg_identity_saved = 'Identité git enregistrée'
        msg_tool_updated   = 'Outil de mise à jour passé à la version {0}'
        msg_done           = 'Terminé : le projet est prêt à ouvrir dans Godot.'
        msg_failed         = 'Arrêté : {0}'
        err_no_git         = 'git.exe introuvable. Installe Git for Windows ou Fork, puis réessaie.'
        err_no_remote      = "Pas d'adresse distante : colle l'adresse GitHub du projet."
        err_fetch          = "le dépôt distant est injoignable (réseau, adresse ou connexion)"
        err_submodules     = "certains add-ons n'ont pas pu être installés"
    }
}

$script:LanguageNames = [ordered]@{ en = 'English'; fr = 'Français' }

function T([string]$key) {
    $table = $script:Strings[$script:Lang]
    $text = if ($table -and $table.ContainsKey($key)) { $table[$key] } else { $script:Strings.en[$key] }
    if ($args.Count) { return $text -f $args }
    return $text
}
