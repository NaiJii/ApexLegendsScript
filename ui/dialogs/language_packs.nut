global function CheckAndShowLanguageDLCDialog
global function LanguageMismatchDialog
global function LanguagePackOutOfDateDialog
global function LanguagePackInstallingDialog

struct
{
	bool seenMismatchDialogue = false
	bool seenOutOfDateDialogue = false
	bool seenInstallingDialogue = false
} file

void function CheckAndShowLanguageDLCDialog()
{
	if ( !IsLanguagePackOwned() )
	{
		LanguageMismatchDialog()
		return
	}

	if ( !IsLanguagePackInstalled() )
	{
		LanguagePackInstallingDialog()
		return
	}

	if ( !IsLanguagePackUpToDate() )
	{
		LanguagePackOutOfDateDialog()
		return
	}
}


void function LanguageMismatchDialog()
{
	if ( file.seenMismatchDialogue )
		return

	string storeName = ""







	DialogData dialogData
	dialogData.header = "#LANGUAGE_PACK_MISMATCH_HEADER"
	dialogData.message = Localize( "#LANGUAGE_PACK_MISMATCH_MESSAGE", storeName )
	dialogData.darkenBackground = true 

	AddDialogButton( dialogData, "#LANGUAGE_PACK_SEE_OPTIONS", SeeStoreOptions )
	AddDialogButton( dialogData, "#B_BUTTON_CLOSE" )

	OpenDialog( dialogData )
	file.seenMismatchDialogue = true
}


void function LanguagePackOutOfDateDialog()
{
	if ( file.seenOutOfDateDialogue )
		return

	DialogData dialogData
	dialogData.header = "#LANGUAGE_PACK_OUT_OF_DATE_HEADER"
	dialogData.message = "#LANGUAGE_PACK_OUT_OF_DATE_MESSAGE"
	dialogData.darkenBackground = true 

	AddDialogButton( dialogData, "#LANGUAGE_PACK_UPDATE_NOW", UpdateNow )
	AddDialogButton( dialogData, "#B_BUTTON_CLOSE" )

	OpenDialog( dialogData )
	file.seenOutOfDateDialogue = true
}


void function LanguagePackInstallingDialog()
{
	if ( file.seenInstallingDialogue )
		return

	DialogData dialogData
	dialogData.header = "#LANGUAGE_PACK_INSTALLING_HEADER"
	dialogData.message = "#LANGUAGE_PACK_INSTALLING_MESSAGE"
	dialogData.darkenBackground = true 

	AddDialogButton( dialogData, "#B_BUTTON_CLOSE" )

	OpenDialog( dialogData )
	file.seenInstallingDialogue = true
}

void function SeeStoreOptions()
{
	PurchaseCurrentLanguagePack()
}

void function UpdateNow()
{



	DownloadCurrentLanguagePack()
}

