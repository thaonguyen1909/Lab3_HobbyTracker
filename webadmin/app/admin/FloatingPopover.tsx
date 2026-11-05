"use client";
import React,{cloneElement,useId,useLayoutEffect,useRef,useState,type ReactElement,type ReactNode} from 'react';
import {createPortal} from 'react-dom';
import {placePopover} from '../../lib/admin/popover-position.mjs';

type Props={open:boolean;onClose:()=>void;trigger:ReactElement<any>;children:ReactNode;className:string;label:string;width?:number};
export default function FloatingPopover({open,onClose,trigger,children,className,label,width=220}:Props){
 const anchor=useRef<HTMLSpanElement>(null),panel=useRef<HTMLDivElement>(null),close=useRef(onClose);
 close.current=onClose;
 const id=useId();const [position,setPosition]=useState<ReturnType<typeof placePopover>|null>(null);
 useLayoutEffect(()=>{
  if(!open){setPosition(null);return}
  const update=()=>{
   if(!anchor.current||!panel.current)return;
   const rect=anchor.current.getBoundingClientRect();
   const viewport={width:document.documentElement.clientWidth,height:window.innerHeight};
   if(rect.bottom<0||rect.top>viewport.height||rect.right<0||rect.left>viewport.width){close.current();return}
   const style=getComputedStyle(panel.current);
   const naturalHeight=panel.current.scrollHeight+parseFloat(style.borderTopWidth||'0')+parseFloat(style.borderBottomWidth||'0');
   setPosition(placePopover(rect,{width,height:naturalHeight},viewport));
  };
  update();
  const observer=new ResizeObserver(update);if(panel.current)observer.observe(panel.current);if(anchor.current)observer.observe(anchor.current);
  const dismiss=(event:PointerEvent)=>{if(!anchor.current?.contains(event.target as Node)&&!panel.current?.contains(event.target as Node))close.current()};
  const keyboard=(event:KeyboardEvent)=>{if(event.key==='Escape'){event.preventDefault();event.stopPropagation();close.current();anchor.current?.querySelector<HTMLButtonElement>('button')?.focus()}};
  window.addEventListener('resize',update);window.addEventListener('scroll',update,true);
  document.addEventListener('pointerdown',dismiss,true);document.addEventListener('keydown',keyboard,true);
  return()=>{observer.disconnect();window.removeEventListener('resize',update);window.removeEventListener('scroll',update,true);document.removeEventListener('pointerdown',dismiss,true);document.removeEventListener('keydown',keyboard,true)};
 },[open,width]);
 return <span ref={anchor} className="floating-anchor">{cloneElement(trigger,{'aria-expanded':open,'aria-controls':open?id:undefined,'aria-haspopup':'dialog'})}{open&&createPortal(<div ref={panel} id={id} role="dialog" aria-label={label} className={`${className} floating-popover`} data-placement={position?.side} style={{position:'fixed',left:position?.left??0,top:position?.top??0,right:'auto',bottom:'auto',width:position?.width??width,minWidth:0,maxWidth:'calc(100vw - 16px)',maxHeight:position?.maxHeight??'calc(100dvh - 16px)',overflowY:'auto',visibility:position?'visible':'hidden',zIndex:75}}>{children}</div>,document.body)}</span>
}
