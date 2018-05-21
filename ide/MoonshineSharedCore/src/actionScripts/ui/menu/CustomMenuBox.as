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
package actionScripts.ui.menu
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.core.ScrollPolicy;
	import mx.graphics.GradientEntry;
	import mx.graphics.LinearGradient;
	
	import spark.components.BorderContainer;
	
	import actionScripts.valueObjects.ConstantsCoreVO;
	
	public class CustomMenuBox extends Canvas
	{
		private var upArrow:BorderContainer;
		private var downArrow:BorderContainer;
		
		public function CustomMenuBox()
		{
			super();
			
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
			
			setStyle("paddingTop", 3);
			setStyle("paddingBottom", 3);
			setStyle("verticalGap", 0);
			setStyle("backgroundColor", 0xf0f0f0);
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			filters = [new DropShadowFilter(5, 55, 0x979797, .22, 5, 5)];
			setStyle("borderStyle", "solid");
			setStyle("borderColor", 0x979797);
			setStyle("borderThickeness", 0);
		}
		
		private function onRemoved(event:Event):void
		{
			this.removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
			if (upArrow)
			{
				upArrow.removeEventListener(MouseEvent.MOUSE_OVER, onUpArrowOver);
				upArrow.removeEventListener(MouseEvent.MOUSE_OUT, onUpArrowOut);
				downArrow.removeEventListener(MouseEvent.MOUSE_OVER, onDownArrowOver);
				downArrow.removeEventListener(MouseEvent.MOUSE_OUT, onDownArrowOut);
				
				downArrow.removeEventListener(Event.ENTER_FRAME, onDownArrowClicked);
				upArrow.removeEventListener(Event.ENTER_FRAME, onUpArrowClicked);
			}
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			if (index != 0 && index <= numChildren)
			{
				var tmpChild:DisplayObject = getChildAt(index - 1);
				child.y = tmpChild.y + tmpChild.height;
			}
			
			return super.addChildAt(child, index);
		}
		
		protected function addScrollButtons():void
		{
			if (!downArrow)
			{
				var upLinearGradient:LinearGradient = new LinearGradient();
				upLinearGradient.rotation = 90;
				upLinearGradient.entries = [new GradientEntry(0xffffff), new GradientEntry(0xcccccc)];
				
				var upArrowImage:Image = new Image();
				upArrowImage.source = new ConstantsCoreVO.up_icon_menu_scroll;
				upArrowImage.horizontalCenter = upArrowImage.verticalCenter = 0;
				
				var downArrowImage:Image = new Image();
				downArrowImage.source = new ConstantsCoreVO.down_icon_menu_scroll;
				downArrowImage.horizontalCenter = downArrowImage.verticalCenter = 0;
				
				upArrow = new BorderContainer();
				upArrow.backgroundFill = upLinearGradient;
				upArrow.height = 20;
				upArrow.addEventListener(MouseEvent.MOUSE_OVER, onUpArrowOver);
				upArrow.addEventListener(MouseEvent.MOUSE_OUT, onUpArrowOut);
				upArrow.visible = false;
				upArrow.y = -2;
				upArrow.addElement(upArrowImage);
				super.addChildAt(upArrow, numChildren);
				
				downArrow = new BorderContainer();
				downArrow.backgroundFill = upLinearGradient;
				downArrow.height = 20;
				downArrow.y = measuredHeight - downArrow.height;
				downArrow.addEventListener(MouseEvent.MOUSE_OVER, onDownArrowOver);
				downArrow.addEventListener(MouseEvent.MOUSE_OUT, onDownArrowOut);
				downArrow.addElement(downArrowImage);
				super.addChildAt(downArrow, numChildren);
			}
		}
		
		private function onDownArrowOver(event:MouseEvent):void
		{
			downArrow.addEventListener(Event.ENTER_FRAME, onDownArrowClicked);
		}
		
		private function onDownArrowOut(event:MouseEvent):void
		{
			downArrow.removeEventListener(Event.ENTER_FRAME, onDownArrowClicked);
		}
		
		private function onUpArrowOver(event:MouseEvent):void
		{
			upArrow.addEventListener(Event.ENTER_FRAME, onUpArrowClicked);
		}
		
		private function onUpArrowOut(event:MouseEvent):void
		{
			upArrow.removeEventListener(Event.ENTER_FRAME, onUpArrowClicked);
		}
		
		private function onDownArrowClicked(event:Event):void
		{
			if (detectMouseOver(downArrow))
			{
				this.verticalScrollPosition += 22;
				downArrow.y += 22;
				upArrow.y += 22;
				upArrow.visible = true;
				
				if (verticalScrollPosition >= maxVerticalScrollPosition)
				{
					this.verticalScrollPosition = this.maxVerticalScrollPosition;
					downArrow.removeEventListener(Event.ENTER_FRAME, onDownArrowClicked);
					downArrow.visible = false;
					upArrow.y -= 16;
					downArrow.y -= 16;
				}
				
			}
		}
		
		private function onUpArrowClicked(event:Event):void
		{
			if (detectMouseOver(upArrow))
			{
				this.verticalScrollPosition -= 22;
				upArrow.y -= 22;
				downArrow.y -= 22;
				downArrow.visible = true;
				
				if (verticalScrollPosition <= 0)
				{
					this.verticalScrollPosition = 0;
					upArrow.removeEventListener(Event.ENTER_FRAME, onDownArrowClicked);
					upArrow.visible = false;
					upArrow.y = -2;
					downArrow.y = measuredHeight - downArrow.height;
				}
			}
		}
		
		private function detectMouseOver(d:DisplayObject):Boolean
		{
			var mousePoint:Point = d.localToGlobal(new Point(d.mouseX,d.mouseY));
			return d.hitTestPoint(mousePoint.x,mousePoint.y,true);
		}
		
		override protected function measure():void
		{
			super.measure();
			if(measuredHeight > this.maxHeight) 
			{
				measuredHeight = this.maxHeight;
				addScrollButtons();
			}
			
			commitProperties();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (downArrow) 
			{
				upArrow.width = downArrow.width = measuredWidth - 2;
			}
		}
	}
}