# Alerter

## Description

Alerter is a LOTRO Lua plugin, written by Garan, that allows you to set specific phrases to watch for in specific chat channels and if any match occurs in a specified channel, a message is displayed prominently on your screen.

This plugin provides the ability to detect and respond to incomming chat messages. Each alert definition has two main sections, Triggers and Responses. The Trigger defines which incomming messages will trigger a specific alert while the Response defines what actions will occur when the alert is triggered. I highly recommend that users read about Lua Patterns in the Lua 5.1 manual at:
http://www.lua.org/manual/5.1/manual.html#5.4.1

Sample alert definitions can be found at:
http://www.lotrointerface.com/portal.php?id=35&a=faq

## Alert definitions:

Language: The Language selection only affects the plugin's GUI and is only provided to make usage easier for FR and DE clients.

Alert: This is the selection list for editing alerts. To edit an existing alert, simply select it from the list. To copy an existing alert, select it from the list and then select <NEW>. To create a new alert, simply select <NEW>.

Label: This is the name of the alert. While the name does not have to be unique

Enabled: Unchecking this box will disable an alert without deleting the definition so that it can be re-enabled at a later date.

Message: This is the text that will be displayed in the alert in response to the matching trigger. If you specified any captures in the Pattern field, you can reference the captured text using %1, %2, %3, etc for first, second, third, etc capture. There are a couple of other special fields:
	%C represents the chat channel number
	%S is the Sender argument from the chat message - unfortunately Lua usually specifies this as the local user even though the message came from an external source
	%M represents the original message text

Shared: Checking this box will save the alert definition in a global file so that it is accessible to all characters on all servers. WARNING, Unchecking this box on any character will remove the global definitioin and save the alert only for that character so all others will lose access to the alert.

Trigger Tab
State: Select a state to see whether the alert is active in that state. The options are Normal, Delayed and Suppressed. Normal alerts will fire normally. Delayed alerts will be delayed until you are no longer in that state. Suppressed alerts will simply be cancelled.

Channel: This is pretty self explanatory, select any and all channels that should be matched for the incomming message pattern. The plugin is slightly more efficient if it can match against fewer channels when comparing incomming messages so the more restrictive you can be the less impact the plugin will have on client performance. If you do not know the channel that you are trying to match, I suggest you use the Show Log button to display raw incomming messages with their channels to locate the correct channel that you wish to match. If the channel is not listed, you can enter the channel number in the Custom Channel field.

Custom Channel: This field is available for users to specify a channel by its number which may be necessary for some FR/DE specific channels as well as channels that are added since the most recent plugin update.

Pattern: This is a Lua Pattern which will be compared to incomming messages in the specified channels. If the Pattern is found in the message, the trigger criteria will be satisfied. At this point, if the Trigger Lua field is not empty, the Trigger Lua code will be called. If the Trigger Lua field is blank or the code returns a non-false value when executed, the alert is fired causing the Response to be generated. See below for more info on the Trigger Lua field.

Response Tab
Duration: This is the time that the alert will be displayed in seconds.

Interval: This is the interval for flashing alerts. To display the alert without flashing, enter 0.

Cooldown: This is the minimum delay between instances of this alert. If another matching trigger event is fired during the Cooldown period it is ignored.

Delay: This is an optional time delay before the alert will be fired. This can be handy when responding to skill usage to fire the alert as a reminder when the skill effect is about to expire.

Display at Mouse: When checked, this will override the positioning of the alert and display it at the current mouse location. This is particularly handy for quickslot alerts since it will position the quickslot for easy clicking.

Save to Custom Log: When checked, this will save an entry in a custom log file with the character, date/time, alert label and original message. The log file is saved in the PluginData/AllServers folder with the file name ".plugindata"

Left, Top, Width and Height: These define the position of the alert. Note that when in Setup mode, there is a red and white checkered border that displays at the position where the alert will display. You can drag the checkered borders to reposition/resize the alert.

Color: This is the color for the text of the alert.

Font: This is a selection list for the font for the alert.

Opacity: This is the opacity of the alert. This can help prevent an alert from overpowering the display when in combat.

Image: This is an optional background image for the alert. If you specify a number it is used as a resource ID for one of the built-in image resources. If you specify a non-numeric value it is used as a path&filename for a jpg or tga file under the Resources folder for the plugin (do not specify the Resources folder portion of the path).

Use Scrolling Text: When checked, the alert will slowly scroll up the screen within the bounds of the alert window, completing its scroll by the end of the Duration.

Quickslot: This set of fields defines a quickslot for a skill, item, alias (chat command), hobby, pet or emote. The easiest way to define the quickslot is to locate the object you wish to activate and drag it to the box to the right of the quickslot data/type fields. The data and type will automatically be filled in for the dropped object. Otherwise you will have to locate the data value manually, by another plugin or via an online source.

Hide after Click: When checked, this will dismiss the alert after the user clicks on the alert/quickslot. If unchecked, the alert will continue to display until the Duration expires.

Custom Lua Tab
One of the newest and most powerful features of the plugin is the ability to specify custom Lua code for Triggers and Responses. Both code snippets are defined on the Custom Code tab. To define a code snippet, simply type or paste the Lua code that you wish to have executed in the text field and save the alert. There are a couple of simple rules, the first of which is that if either code snippet is not blank, it MUST return a non-false value or the alert will be cancelled. This allows the Lua code to abort an alert altogether in the Trigger snippet or to define a custom response and abort the default response in the Response snippet. The second rule has to do with variable scoping. Each code snippet will be executed in the environment of the plugin with access to all of the non-local variables of the plugin. Additionally, there is an "args" table which contains a number of values that may be of interest to end users. Note that all of the elements of the args table are local copies except the args.captures which is a sub-table and contains the Lua string matching captures from the defined Pattern. If the code snippet alteres the contents of the args.captures values, those alterations will be passed on and will be available to the Message that is displayed by the alert using %1, %2, etc. Additionally, when clicking the Test button, the plugin will pass the contents of the Message field as the original message or the Pattern field if the Message field is blank.

Save Button: Pretty self-explanatory, clicking this button saves the alert definition.

Test Button: This button will allow you to test the Response settings and the Custom Lua code. It will NOT test the Trigger settings. To test the Trigger settings, I recommend clicking the "All" channel option and sending yourself a text message containing the exact text you wish to test. If the message contains special characters or tags you may have to use another plugin such as RainBow Chat to generate the test. Otherwise you will have to get the client to generate the actual message.

Show Log Button: This displays the chat log window. This window can be handy to determine the correct channel and exact underlying chat text for a message you wish to use as a trigger.

Delete Button: Again, pretty self-explanatory, clicking this button deletes the alert definition.

## Version History

### Version 1.08
Added custom Lua code snippets for Trigger and Response. The Trigger snippet can be used to provide custom filtering of alerts while the Response snippet can be used to define additional response capabilities or alter the existing responses.
To learn more about the code snippets and their capabilites, read the ReadMe.txt file.
Changed "Show Log" Button to "Show Chat Log" to reflect that it is a log of incomming Chat messages
Changed "Add to Custom Log" Checkbox to "Add to Alert Log" and added "Show Alert Log" Button to view the log of alerts.
Added Log Viewer window. This window will display the history of alerts that had the "Add to Alert Log" check box checked during a specific session. I recommend not logging alerts unless you are trying to debug something as the log viewer doesn't handle large tables very well. However, it does have a couple of handy features:
  You can left drag column headings to reorder the columns, you can left drag the header separators to resize columns and you can right click the header to check/uncheck columns to be displayed
  You can control the size of the text in the grid by selecting a font and size by clicking the font select button in the upper right corner. You can also increase/decrease the font by simply holding Ctrl and scrolling your mouse wheel while over the grid - note, the font change can take a second or two for large tables so it is best to select a font while reviewing a session with fewer alerts to find a font that is comfortable.
  The Response column is the actual text displayed by the Alert while the Message column is the original text from the incomming Chat message that triggered the alert.

### Version 1.07
Restored Shared alerts and Custom Logs that were accidentally removed in 1.06
Added "message" to Custom Logs.
Note, Custom Logs are log files per client session that are stored at the account level, in the AllServers folder, as "Alerter_Log_YYYYMMDD_HHMMSS.plugindata" where YYYYMMDD is Year, Month and Day and HHMMSS is Hours, Minutes and Seconds. A log viewer is planned for a future version.

### Version 1.06
Added "World" chat channel
Added support for Emote, Pet and Hobby quickslots in Responses
Changed default behavior of quickslots to display for Duration and added option to "Hide after Clicked"

### Version 1.05
Fixed alert position bug for alerts using Mouse Position and a Delay time.
Fixed bug that could generate an error when displaying the "Alert Saved" or "Alert Deleted" message.
Fixed bug in language selection not immediately updating State radio button labels and selection list labels.

### Version 1.04
Added separate tabs for Trigger settings and Result settings to help group settings and clean up the cluttered interface
Updated the DE and FR support. The whole interface should now support both German and French (although some translations may still be a bit literal).
Changed channel select boxes to automatically reorder alphabetically when language changes.
Added the new channels from Update 6 (Combat - Player and Combat - Enemy).
Changed Item quickslots to accept item instance IDs instead of generic IDs (the first part of the ID should not be 0). Use drag & drop to generate the ID. Note, for items with more than one stack, only the stack that is actually dragged to the control will work.
Implemented permanent fix for the version 1.03 infinite loop bug caused by ExaminationItemID tags containing byte data.
Added Delay setting for alerts - you can now trigger an alert to go off x number of seconds after the chat message which is great for knowing when to refresh certain skills, etc.
Added States (currently only "In Combat" and "Out of Combat") for triggers. You can choose to delay an alert until the state is no longer true or suppress he alert all together. This way you won't be bothered by social alerts while in combat (but you can choose to have them pop up once combat ends), etc.
Fixed a bug that could allow an alert Quickslot to continue to display even after the alert duration had expired.

### Version 1.03
Modified Alerts so that more than one alert can be active simultaneously - alerts no longer override each other.
Added limits to the alert template when resizing with the mouse - you can still override the limits by manually entering lower values.
Re-added the Opacity slider
Added tinting to areas of the setup panel to indicate related fields and help a little with the clutter
Added Quickslot controls to alerts - these let you click on the alert to execute an alias, perform a skill or use an item
Added an option to display alert at the mouse position, overriding the Top and Left coordinates (mostly useful for Quickslot alerts)
Added an option to scroll the text vertically upwards within the defined alert box - the scroll rate is controlled by the duration

### Version 1.02
Added Cooldown setting to alerts - allows setting a minimum time between alerts for the same trigger.
Added a graphical frame which is visible when the setup window is visible for graphically moving/resizing the alert panel in addition to left, top, width and height fields that can be manually entered.
Added the ability to use a graphic image with alerts. Save the image in the GaranStuff/Alerter/Resources folder and then just enter the image file name (without path). Alternately, you can use any of the built in resource IDs.
Added a chat log which displays the chat channel, sender and message arguments for the last 1000 incomming chat messages.
Altered the way that channels are selected - you will need to redefine any previously created alerts by reselecting the channels and resaving.
Added a "Custom" channel to allow users to match agains any previously undefined channel that they find in the log. Undefined channels will show up as a number, enter that number in the Custom Channel field. Note, undefined channels will still be matched by the "Any" channel category.
Added the ability to use "captures" in the Pattern which can be reproduced in the alert Message by inserting a %number where "number" is the iteration of the capture.
note that the captures do not need to be reproduced in the order in which they were captured, that is %2 can preceed %1 in the Message.
When creating patterns, note that the incomming message may not be quite what you expect, the built in chat window processes some of the text before adding it to the chat display. For instance, "Tells" do not include the sender's name or the words "tells you," in the message, those are added by the chat window.
The Message field can contain three special fields, %C for the Channel and %S for the Sender and %M for the original Message.
Added a chat command to Start, Stop and Show the Chat Log - "/Alerter Log Start","/Alerter Log Stop","/Alerter Log Show"
Added an "Enabled" checkbox. Clear this to temporarily disable an alert without having to delete the alert definition.

### Version 1.01
Added a Delete button
Added French and German translations for most of the interface, Chat channels are not yet translated
Fixed incorrect label for the Font selection list
Fixed the mouse click-though bug (reported by Eldarian on LoTROInterface).
