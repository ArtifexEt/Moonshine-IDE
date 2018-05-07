////////////////////////////////////////////////////////////////////////////////
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0 
// 
// Unless required by applicable law or agreed to in writing, software 
// distributed under the License is distributed on an "AS IS" BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and 
// limitations under the License
// 
// No warranty of merchantability or fitness of any kind. 
// Use this software at your own risk.
// 
////////////////////////////////////////////////////////////////////////////////
package actionScripts.plugin.console
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.containers.dividedBoxClasses.BoxDivider;
	import mx.events.DividerEvent;
	import mx.managers.CursorManager;
	import mx.managers.CursorManagerPriority;
	import mx.resources.ResourceManager;
	
	import actionScripts.plugin.IPlugin;
	import actionScripts.plugin.PluginBase;
	import actionScripts.plugin.console.setting.SpecialKeySetting;
	import actionScripts.plugin.console.view.ConsoleModeEvent;
	import actionScripts.plugin.console.view.ConsoleView;
	import actionScripts.plugin.settings.ISettingsProvider;
	import actionScripts.plugin.settings.vo.BooleanSetting;
	import actionScripts.plugin.settings.vo.ISetting;
	import actionScripts.ui.LayoutModifier;
	import actionScripts.ui.menu.MenuPlugin;
	import actionScripts.valueObjects.ConstantsCoreVO;
	
	/**
	 *  @private
	 *  Version string for this class.
	 */
	public class ConsolePlugin extends PluginBase implements IPlugin, ISettingsProvider
	{
		[Embed("/elements/images/Divider_collapse.png")]
		private const customDividerSkinCollapse:Class;
		[Embed("/elements/images/Divider_expand.png")]
		private const customDividerSkinExpand:Class;
		/*[Embed(source="Assets.swf", symbol="mx.skins.cursor.HandCursor")]
		private var cursor:Class;*/
		
		private var consoleView:ConsoleView;
		private var _consolePopsOver:Boolean = false;
		private var loadedFirstTime:Boolean = true;
		private var consoleCmd:Boolean  =false;
		private var consoleCtrl:Boolean = false;
		private var mode:String = "";
		private var _consoleTriggerKey:String;
		private var cursorID:int = CursorManager.NO_CURSOR;
		private var _isConsoleHidden:Boolean = false;
		
		public var consoleTriggerKeyPropertyName:String = "charCode";
		public var consoleTriggerKeyValue:int = 27; // Escape
		public var ctrl:Boolean = false;
		public var alt:Boolean = false;
		public var cmd:Boolean = false;
		
		public function get consolePopsOver():Boolean
		{
			return _consolePopsOver;
		}
		public function set consolePopsOver(v:Boolean):void
		{
			_consolePopsOver = v;
			if (consoleView) consoleView.consolePopOver = v;
		}
		
		public function get showDebugMessages():Boolean
		{
			return ConsoleOutputter.DEBUG;
		}
		public function set showDebugMessages(v:Boolean):void
		{
			ConsoleOutputter.DEBUG = v;
		} 
		
		override public function get name():String { return "Console"; }
		override public function get author():String { return "Erik Pettersson & Moonshine Project Team"; }
		override public function get description():String { return ResourceManager.getInstance().getString('resources','plugin.desc.console'); }
		
		override public function activate():void
        {
            consoleView = new ConsoleView();
            consoleView.consolePopOver = consolePopsOver;

            if (model.mainView)
            {
                setConsoleHidden(LayoutModifier.isConsoleCollapsed);

                model.mainView.bodyPanel.addChild(consoleView);
                model.mainView.bodyPanel.addEventListener(DividerEvent.DIVIDER_RELEASE, onConsoleDividerReleased, false, 0, true);
                model.mainView.mainPanel.addEventListener(DividerEvent.DIVIDER_RELEASE, onSidebarDividerReleased, false, 0, true);

                var divider:BoxDivider = model.mainView.bodyPanel.getDividerAt(0);
                divider.addEventListener(MouseEvent.MOUSE_MOVE, onDividerMouseOver, false, 0, true);
                divider.addEventListener(MouseEvent.MOUSE_OUT, onDividerMouseOut, false, 0, true);
            }
            if (consoleView.stage)
            {
                addKeyListener();
            }
            else
            {
                consoleView.addEventListener(Event.ADDED_TO_STAGE, addKeyListener);
            }

            dispatcher.addEventListener(ConsoleOutputEvent.CONSOLE_OUTPUT, addOutputHandler);
			dispatcher.addEventListener(ConsoleOutputEvent.CONSOLE_PRINT, addOutputPrintHandler);
            dispatcher.addEventListener(ConsoleOutputEvent.CONSOLE_CLEAR, clearOutputHandler);

            dispatcher.addEventListener(ConsoleModeEvent.CHANGE, changeMode);

            var tempObj:Object = {};
            tempObj.callback = clearCommand;
            tempObj.commandDesc = "Clear all text from the console.";
            registerCommand("clear", tempObj);

            tempObj = {};
            tempObj.callback = helpCommand;
            tempObj.commandDesc = "List the available console commands.";
            registerCommand("help", tempObj);

            tempObj = {};
            tempObj.callback = hideCommand;
            tempObj.commandDesc = "Minimize the console frame.  Click and drag to expand it againMinimize the console frame.  Click and drag to expand it again..";
            registerCommand("hide", tempObj);

            tempObj = {};
            tempObj.callback = exitCommand;
            tempObj.commandDesc = "Close Moonshine.  You will be prompted to save any unsaved files.";
            registerCommand("exit", tempObj);

            tempObj = {};
            tempObj.callback = aboutCommand;
            tempObj.commandDesc = "Display version and license information for Moonshine.";
            registerCommand("about", tempObj);

            // Get commands from view
            consoleView.commandLine.addEventListener(ConsoleCommandEvent.EVENT_COMMAND, execCommand);

            // just a demo output
            //About.onCreationCompletes();
            var timeoutValue:uint = setTimeout(function():void{
				aboutCommand(null);
				clearTimeout(timeoutValue);
        	}, 3000);
        }
		
		override public function deactivate():void
		{
			if (consoleView && consoleView.parent)
			{
				consoleView.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
				consoleView.parent.removeChild(consoleView);
			}
			
			unregisterCommand("clear");
			unregisterCommand("hide");
			unregisterCommand("exit");
			unregisterCommand("help");
			
			dispatcher.removeEventListener(ConsoleOutputEvent.CONSOLE_OUTPUT, addOutputHandler);
			dispatcher.removeEventListener(ConsoleOutputEvent.CONSOLE_PRINT, addOutputPrintHandler);
            dispatcher.removeEventListener(ConsoleOutputEvent.CONSOLE_CLEAR, clearOutputHandler);

			dispatcher.removeEventListener(ConsoleModeEvent.CHANGE, changeMode);
		}
		
		override public function get activated():Boolean
		{
			return (consoleView != null);
		}
		
		override public function resetSettings():void
		{
			consoleTriggerKey = null;
			consolePopsOver = false;
			showDebugMessages = true;
		}
		
		private var isOverTheExpandCollapseButton:Boolean;
		private function onDividerMouseOver(event:MouseEvent):void
		{
			onDividerMouseOut(null);
			
			var dividerWidth:Number = event.target.width;
			// divider skin width is 67
			var parts:Number = (dividerWidth - 67)/2;
			if (event.localX < parts || event.localX > parts+67)
			{
				var cursorClass:Class = event.target.getStyle("verticalDividerCursor") as Class;
				cursorID = model.mainView.bodyPanel.cursorManager.setCursor(cursorClass, CursorManagerPriority.HIGH, 0, 0);
				isOverTheExpandCollapseButton = false;
			}
			else
			{
				isOverTheExpandCollapseButton = true;
			}
		}
		
		private function onDividerMouseOut(event:MouseEvent):void
		{
			model.mainView.bodyPanel.cursorManager.removeCursor(cursorID);
			model.mainView.bodyPanel.cursorManager.removeCursor(model.mainView.bodyPanel.cursorManager.currentCursorID);
		}
		
		private function onConsoleDividerReleased(event:DividerEvent):void
		{
			// consider an expand/collapse click
			if (isOverTheExpandCollapseButton)
			{
				setConsoleHidden(!_isConsoleHidden);
				if (!_isConsoleHidden) 
				{
					if (LayoutModifier.consoleHeight != -1) consoleView.setOutputHeight(LayoutModifier.consoleHeight);
					else consoleView.setOutputHeightByLines(10);
				}
				else 
				{
					consoleView.setOutputHeight(0);
				}
				
				return;
			}
			
			var tmpHeight:int = consoleView.parent.height-consoleView.parent.mouseY-consoleView.minHeight;
			if (tmpHeight <= 2) 
			{
				setConsoleHidden(true);
				LayoutModifier.consoleHeight = -1;
			}
			else 
			{
				setConsoleHidden(false);
				LayoutModifier.consoleHeight = tmpHeight;
			}
		}
		
		private function onSidebarDividerReleased(event:DividerEvent):void
		{
			LayoutModifier.sidebarWidth = event.target.mouseX;
		}
		
		private function setConsoleHidden(value:Boolean):void
		{
			LayoutModifier.isConsoleCollapsed = value;
			_isConsoleHidden = value;
			model.mainView.bodyPanel.setStyle('dividerSkin', !_isConsoleHidden ? customDividerSkinCollapse : customDividerSkinExpand);
		}
		
		private function addKeyListener(event:Event=null):void
		{
			consoleView.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
		}
		
		private function handleKeyDown(event:KeyboardEvent):void
		{
			if(event.keyCode == 15 )
				consoleCmd = true;
			if(event.keyCode == 17)
				consoleCtrl = true;
			//cmd 17ctrl
			
			if (consoleTriggerKeyPropertyName=="charCode" && event[consoleTriggerKeyPropertyName] == consoleTriggerKeyValue)
			{
				// For combinatio key
				if(cmd && consoleCmd)//for command key
				{
					toggleConsole(event);
				}
				else if(ctrl && consoleCtrl )// for Control Key
				{
					toggleConsole(event);
				}
				else if(alt && event.altKey)
				{
					toggleConsole(event);
				}
			}
			
		}
		
		public function get consoleTriggerKey():String
		{
			return _consoleTriggerKey;
		}
		
		public function set consoleTriggerKey(value:String):void
		{
			_consoleTriggerKey = value;
			if (value)
			{
				var values:Array = value.split(":");
				consoleTriggerKeyPropertyName = values[0];
				alt  = (values[2]=="false"?false:true);
				ctrl = (values[3]=="false"?false:true);
				cmd  = (values[4]=="false"?false:true);
				consoleCmd = false;
				consoleCtrl = false;
				consoleTriggerKeyValue = parseInt(values[1]);
			}
		}
		public function getSettingsList():Vector.<ISetting>
		{
			return Vector.<ISetting>([
				new SpecialKeySetting(this, "consoleTriggerKey", "Console trigger key",consoleTriggerKey),
				new BooleanSetting(this, "consolePopsOver", "Console should glide over editor"),// This line is commented for now becuase it only hide console view for now 
				new BooleanSetting(this, "showDebugMessages", "Show Moonshine debug messages")
			]);
		}
		
		private function toggleConsole(event:KeyboardEvent):void
		{
			if (consoleView.stage.focus != consoleView.commandLine)
			{
				event.preventDefault();
				consoleView.commandLine.setFocus();
				consoleCmd = false;
				consoleCtrl = false;
			}
		}
		
		
		private function changeMode(e:ConsoleModeEvent):void 
		{
			mode = e.mode;
			consoleView.commandPrefix.text = " "+mode+">"
		}
		
		private function execCommand(event:ConsoleCommandEvent):void
		{
			if (mode == "")	
			{
				if (console::commands[event.command])
				{
					var obj:Object = console::commands[event.command];
					var func:Function = obj.callback;
					func(event.args);
					//console::commands[event.command](event.args);	
				}
				else
				{
					print("%s: command not found", event.command);
				}
			} 
			else 
			{
				// Command is an argument in a mode
				var args:Array = [event.command];
				args = args.concat(event.args);
				console::commands[mode](args);
			}
		}

		private function clearOutputHandler(event:ConsoleOutputEvent):void
		{
            consoleView.history.text = "";
		}

		private function addOutputHandler(event:ConsoleOutputEvent):void
		{
			var numNewLines:int = consoleView.history.appendtext(event.text);

			if (!LayoutModifier.isConsoleCollapsed && LayoutModifier.consoleHeight != -1)
			{
				consoleView.setOutputHeight(LayoutModifier.consoleHeight);
				loadedFirstTime = false;
			}
			else if (loadedFirstTime && consoleView.history.numVisibleLines < numNewLines)
			{
				consoleView.setOutputHeightByLines(numNewLines);
				loadedFirstTime = false;
			}
		}
		
		private function addOutputPrintHandler(event:ConsoleOutputEvent):void
		{
			switch(event.messageType)
			{
				case ConsoleOutputEvent.TYPE_ERROR:
					error(event.text);
					break;
				case ConsoleOutputEvent.TYPE_SUCCESS:
					success(event.text);
					break;
				case ConsoleOutputEvent.TYPE_NOTE:
					notice(event.text);
					break;
				default:
					print(event.text);
					break;
			}
		}

		public function clearCommand(args:Array):void
		{
			dispatcher.dispatchEvent(new ConsoleOutputEvent(ConsoleOutputEvent.CONSOLE_CLEAR, null, true));
		}

		public function exitCommand(args:Array):void
		{
			dispatcher.dispatchEvent( new Event(MenuPlugin.MENU_QUIT_EVENT) );
		}
		
		public function hideCommand(args:Array):void
		{
			/*consoleView.setOutputHeight(0);
			var model:IDEModel = model;
			if (model.activeEditor) model.activeEditor.setFocus();*/
			setConsoleHidden(true);
		}
		
		public function helpCommand(args:Array):void
		{
			var cmds:Array = [];
			for (var cmd:String in console::commands)
			{
				var obj:Object = console::commands[cmd];
				cmds.push(cmd +" - <font color='#4C9BE0'> " +obj.commandDesc+"</font>");	
			}
			cmds = cmds.sort();
			
			var halp:String = "Available commands:\n";
			for each (cmd in cmds)
			{				
				halp += cmd + "\n";
			}
			
			halp = halp.substr(0, halp.length-1);
			outputMsg(halp);
		}
		
		public function aboutCommand(args:Array):void
		{
			var ntc:String = "Moonshine IDE "+ model.flexCore.version +"\n";
			ntc += "Source code is under Apache License, Version 2.0\n";
			ntc += "https://github.com/prominic/Moonshine-IDE\n";
			ntc += "Uses as3abc (LGPL), as3swf (MIT), fzip (ZLIB), asblocks (Apache License 2.0), NativeApplicationUpdater (LGPL)\n";
			
			if (ConstantsCoreVO.IS_AIR) ntc += "Running on Adobe AIR " + model.flexCore.runtimeVersion;
			notice(ntc);
		}
	}
}
