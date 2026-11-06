import test from 'node:test';
import assert from 'node:assert/strict';
import {placePopover} from '../src/lib/admin/popover-position.mjs';
const viewport={width:1280,height:800};
test('top rows open below the actual clicked button',()=>{const p=placePopover({top:100,bottom:134,right:1200},{width:230,height:340},viewport);assert.equal(p.side,'bottom');assert.equal(p.top,140);assert.equal(p.left,970)});
test('bottom rows open above without overlapping the trigger or viewport edge',()=>{const p=placePopover({top:720,bottom:754,right:1200},{width:230,height:340},viewport);assert.equal(p.side,'top');assert.equal(p.top,374);assert.ok(p.top+340<720)});
test('narrow mobile screens clamp width and horizontal position',()=>{const p=placePopover({top:50,bottom:84,right:40},{width:290,height:200},{width:240,height:600});assert.equal(p.width,224);assert.equal(p.left,8);assert.ok(p.left+p.width<=232)});
test('short viewports constrain long menus to available space with internal scrolling',()=>{const p=placePopover({top:160,bottom:194,right:300},{width:230,height:500},{width:360,height:300});assert.equal(p.side,'top');assert.equal(p.maxHeight,146);assert.equal(p.top,8)});
test('resizing or scrolling recomputes side and location from current anchor geometry',()=>{const content={width:230,height:300};const down=placePopover({top:100,bottom:134,right:500},content,viewport);const up=placePopover({top:650,bottom:684,right:400},content,viewport);assert.equal(down.side,'bottom');assert.equal(up.side,'top');assert.equal(up.left,170);assert.equal(up.top,344)});
