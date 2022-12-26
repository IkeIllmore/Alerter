This plugin provides the ability to detect and respond to incomming chat messages. Each alert definition has two main sections, Triggers and Responses. The Trigger defines which incomming messages will trigger a specific alert while the Response defines what actions will occur when the alert is triggered. I highly recommend that users read about Lua Patterns in the Lua 5.1 manual at:
http://www.lua.org/manual/5.1/manual.html#5.4.1

Sample alert definitions can be found at:
http://www.lotrointerface.com/portal.php?id=35&a=faq

Alert definitions:

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
