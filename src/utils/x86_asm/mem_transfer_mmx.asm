;/****************************************************************************
; *
; *  XVID MPEG-4 VIDEO CODEC
; *  - 8<->16 bit transfer functions -
; *
; *  Copyright (C) 2001 Peter Ross <pross@xvid.org>
; *                2001 Michael Militzer <isibaar@xvid.org>
; *                2002 Pascal Massimino <skal@planet-d.net>
; *                2004 Jean-Marc Bastide <jmtest@voila.fr>
; *
; *  This program is free software ; you can redistribute it and/or modify
; *  it under the terms of the GNU General Public License as published by
; *  the Free Software Foundation ; either version 2 of the License, or
; *  (at your option) any later version.
; *
; *  This program is distributed in the hope that it will be useful,
; *  but WITHOUT ANY WARRANTY ; without even the implied warranty of
; *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; *  GNU General Public License for more details.
; *
; *  You should have received a copy of the GNU General Public License
; *  along with this program ; if not, write to the Free Software
; *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
; *
; * $Id: mem_transfer_mmx.asm,v 1.11 2004-04-12 15:49:56 edgomez Exp $
; *
; ***************************************************************************/

BITS 32

%macro cglobal 1
	%ifdef PREFIX
		global _%1
		%define %1 _%1
	%else
		global %1
	%endif
%endmacro

;=============================================================================
; Read only data
;=============================================================================

%ifdef FORMAT_COFF
SECTION .rodata data
%else
SECTION .rodata data align=16
%endif

ALIGN 16
mmx_one:
	dw 1, 1, 1, 1

;=============================================================================
; Code
;=============================================================================

SECTION .text

cglobal transfer_8to16copy_mmx
cglobal transfer_16to8copy_mmx
cglobal transfer_8to16sub_mmx
cglobal transfer_8to16subro_mmx
cglobal transfer_8to16sub2_mmx
cglobal transfer_8to16sub2_xmm
cglobal transfer_16to8add_mmx
cglobal transfer8x8_copy_mmx

;-----------------------------------------------------------------------------
;
; void transfer_8to16copy_mmx(int16_t * const dst,
;							const uint8_t * const src,
;							uint32_t stride);
;
;-----------------------------------------------------------------------------

%macro COPY_8_TO_16 1
  movq mm0, [eax]
  movq mm1, [eax+edx]
  movq mm2, mm0
  movq mm3, mm1
  punpcklbw mm0, mm7
  movq [ecx+%1*32], mm0
  punpcklbw mm1, mm7
  movq [ecx+%1*32+16], mm1
  punpckhbw mm2, mm7
  punpckhbw mm3, mm7
  lea eax, [eax+2*edx]
  movq [ecx+%1*32+8], mm2
  movq [ecx+%1*32+24], mm3
%endmacro

ALIGN 16
transfer_8to16copy_mmx:

  mov ecx, [esp+ 4] ; Dst
  mov eax, [esp+ 8] ; Src
  mov edx, [esp+12] ; Stride
  pxor mm7, mm7

  COPY_8_TO_16 0
  COPY_8_TO_16 1
  COPY_8_TO_16 2
  COPY_8_TO_16 3
  ret

;-----------------------------------------------------------------------------
;
; void transfer_16to8copy_mmx(uint8_t * const dst,
;							const int16_t * const src,
;							uint32_t stride);
;
;-----------------------------------------------------------------------------

%macro COPY_16_TO_8 1
  movq mm0, [eax+%1*32]
  movq mm1, [eax+%1*32+8]
  packuswb mm0, mm1
  movq [ecx], mm0
  movq mm2, [eax+%1*32+16]
  movq mm3, [eax+%1*32+24]
  packuswb mm2, mm3
  movq [ecx+edx], mm2
%endmacro

ALIGN 16
transfer_16to8copy_mmx:

  mov ecx, [esp+ 4] ; Dst
  mov eax, [esp+ 8] ; Src
  mov edx, [esp+12] ; Stride

  COPY_16_TO_8 0
  lea ecx,[ecx+2*edx]
  COPY_16_TO_8 1
  lea ecx,[ecx+2*edx]
  COPY_16_TO_8 2
  lea ecx,[ecx+2*edx]
  COPY_16_TO_8 3
  ret

;-----------------------------------------------------------------------------
;
; void transfer_8to16sub_mmx(int16_t * const dct,
;				uint8_t * const cur,
;				const uint8_t * const ref,
;				const uint32_t stride);
;
;-----------------------------------------------------------------------------

; when second argument == 1, reference (ebx) block is to current (eax)
%macro COPY_8_TO_16_SUB 2
  movq mm0, [eax]      ; cur
  movq mm2, [eax+edx]

  movq mm4, [ebx]      ; ref
  movq mm5, [ebx+edx]  ; ref

%if %2 == 1
  movq [eax], mm4
  movq [eax+edx], mm5
%endif

  lea eax, [eax+2*edx]
  
  psubsb mm0,mm4
  psubsb mm2,mm5
  lea ebx,[ebx+2*edx]
  
  movq mm1,mm0
  movq mm3,mm2
  punpcklbw mm0,mm7
  punpckhbw mm1,mm7
  punpcklbw mm2,mm7
  punpckhbw mm3,mm7

  movq [ecx+%1*32+ 0], mm0 ; dst
  movq [ecx+%1*32+ 8], mm1
  movq [ecx+%1*32+16], mm2
  movq [ecx+%1*32+24], mm3
%endmacro

ALIGN 16
transfer_8to16sub_mmx:
  mov ecx, [esp  + 4] ; Dst
  mov eax, [esp  + 8] ; Cur
  push ebx
  mov ebx, [esp+4+12] ; Ref
  mov edx, [esp+4+16] ; Stride
  pxor mm7, mm7

  COPY_8_TO_16_SUB 0, 1
  COPY_8_TO_16_SUB 1, 1
  COPY_8_TO_16_SUB 2, 1
  COPY_8_TO_16_SUB 3, 1

  pop ebx
  ret


ALIGN 16
transfer_8to16subro_mmx:
  mov ecx, [esp  + 4] ; Dst
  mov eax, [esp  + 8] ; Cur
  push ebx
  mov ebx, [esp+4+12] ; Ref
  mov edx, [esp+4+16] ; Stride
  pxor mm7, mm7

  COPY_8_TO_16_SUB 0, 0
  COPY_8_TO_16_SUB 1, 0
  COPY_8_TO_16_SUB 2, 0
  COPY_8_TO_16_SUB 3, 0

  pop ebx
  ret


;-----------------------------------------------------------------------------
;
; void transfer_8to16sub2_mmx(int16_t * const dct,
;				uint8_t * const cur,
;				const uint8_t * ref1,
;				const uint8_t * ref2,
;				const uint32_t stride)
;
;-----------------------------------------------------------------------------

%macro COPY_8_TO_16_SUB2_MMX 1
  movq mm0, [eax]      ; cur
  movq mm2, [eax+edx]
 
  ; mm4 <- (ref1+ref2+1) / 2
  ;(a+b+1)/2 = (a|b)-((a^b)>>1)
  movq mm4, [ebx]      ; ref1
  movq mm1, [esi]      ; ref2
  movq mm3, mm4
  pxor mm3,mm1
  por mm4,mm1
  pandn mm3,mm6
  psrlq mm3,1
  psubb mm4,mm3
  movq [eax],mm4
  
  ; mm5 <- (ref1+ref2+1) / 2
  movq mm5, [ebx+edx]  ; ref1
  movq mm1, [esi+edx]  ; ref2
  movq mm3, mm5
  pxor mm3,mm1
  por mm5,mm1
  pandn mm3,mm6
  psrlq mm3,1
  psubb mm5,mm3
  movq [eax+edx],mm5
  
  psubsb mm0,mm4
  psubsb mm2,mm5
  lea esi, [esi+2*edx]
  movq mm1,mm0
  movq mm3,mm2
  lea eax, [eax+2*edx]
  punpcklbw mm0,mm7
  punpcklbw mm2,mm7
  lea ebx, [ebx+2*edx]
  punpckhbw mm1,mm7
  punpckhbw mm3,mm7
  
  movq [ecx+%1*32+ 0], mm0 ; dst
  movq [ecx+%1*32+ 8], mm1
  movq [ecx+%1*32+16], mm2
  movq [ecx+%1*32+24], mm3
%endmacro

ALIGN 16
transfer_8to16sub2_mmx:
  mov ecx, [esp  + 4] ; Dst
  mov eax, [esp  + 8] ; Cur
  push ebx
  mov ebx, [esp+4+12] ; Ref1
  push esi
  mov esi, [esp+8+16] ; Ref2
  mov edx, [esp+8+20] ; Stride
  pxor mm6,mm6
  pcmpeqb mm5,mm5
  pxor mm7, mm7
  psubb mm6, mm5; mm6=1

  COPY_8_TO_16_SUB2_MMX 0
  COPY_8_TO_16_SUB2_MMX 1
  COPY_8_TO_16_SUB2_MMX 2
  COPY_8_TO_16_SUB2_MMX 3

  pop esi
  pop ebx
  ret

;-----------------------------------------------------------------------------
;
; void transfer_8to16sub2_xmm(int16_t * const dct,
;				uint8_t * const cur,
;				const uint8_t * ref1,
;				const uint8_t * ref2,
;				const uint32_t stride)
;
;-----------------------------------------------------------------------------

%macro COPY_8_TO_16_SUB2_SSE 1
  movq mm0, [eax]      ; cur
  movq mm2, [eax+edx]

  movq mm4, [ebx]     ; ref1
  pavgb mm4, [esi]     ; ref2

  movq mm5, [ebx+edx] ; ref
  pavgb mm5, [esi+edx] ; ref2
  
  movq [eax], mm4
  movq [eax+edx], mm5 

  psubsb mm0,mm4
  psubsb mm2,mm5
  lea esi, [esi+2*edx]
  movq mm1,mm0
  movq mm3,mm2
  lea eax, [eax+2*edx]
  punpcklbw mm0,mm7
  punpcklbw mm2,mm7
  lea ebx, [ebx+2*edx]
  punpckhbw mm1,mm7
  punpckhbw mm3,mm7
  
  movq [ecx+%1*32+ 0], mm0 ; dst
  movq [ecx+%1*32+ 8], mm1
  movq [ecx+%1*32+16], mm2
  movq [ecx+%1*32+24], mm3
%endmacro

ALIGN 16
transfer_8to16sub2_xmm:
  mov ecx, [esp  + 4] ; Dst
  mov eax, [esp  + 8] ; Cur
  push ebx
  mov ebx, [esp+4+12] ; Ref1
  push esi
  mov esi, [esp+8+16] ; Ref2
  mov edx, [esp+8+20] ; Stride
  pxor mm7, mm7

  COPY_8_TO_16_SUB2_SSE 0
  COPY_8_TO_16_SUB2_SSE 1
  COPY_8_TO_16_SUB2_SSE 2
  COPY_8_TO_16_SUB2_SSE 3

  pop esi
  pop ebx
  ret

;-----------------------------------------------------------------------------
;
; void transfer_16to8add_mmx(uint8_t * const dst,
;						const int16_t * const src,
;						uint32_t stride);
;
;-----------------------------------------------------------------------------

%macro COPY_16_TO_8_ADD 1
  movq mm0, [eax+%1*32+ 0] ;src
  packuswb mm0,[eax+%1*32+8]
  movq mm1, [eax+%1*32+ 16] 
  packuswb mm1,[eax+%1*32+24]
  
  paddusb mm0,[ecx]
  paddusb mm1,[ecx+edx]
  movq [ecx],mm0
  movq [ecx+edx],mm1

%endmacro


ALIGN 16
transfer_16to8add_mmx:
  mov ecx, [esp+ 4] ; Dst
  mov eax, [esp+ 8] ; Src
  mov edx, [esp+12] ; Stride
 ; pxor mm7, mm7

  COPY_16_TO_8_ADD 0
  lea ecx,[ecx+2*edx]
  COPY_16_TO_8_ADD 1
  lea ecx,[ecx+2*edx]
  COPY_16_TO_8_ADD 2
  lea ecx,[ecx+2*edx]
  COPY_16_TO_8_ADD 3
  ret

;-----------------------------------------------------------------------------
;
; void transfer8x8_copy_mmx(uint8_t * const dst,
;					const uint8_t * const src,
;					const uint32_t stride);
;
;
;-----------------------------------------------------------------------------

ALIGN 16
transfer8x8_copy_mmx:

  mov eax, [esp+ 8] ; Src
  mov ecx, [esp+ 4] ; Dst
  mov edx, [esp+12] ; Stride
  
  movq mm0,[eax]
  lea eax,[eax+edx]
  movq mm1,[eax]
  lea eax,[eax+edx]
  movq mm2,[eax]
  lea eax,[eax+edx]
  movq mm3,[eax]
  lea eax,[eax+edx]
  movq mm4,[eax]
  lea eax,[eax+edx]
  movq mm5,[eax]
  lea eax,[eax+edx]
  movq mm6,[eax]
  lea eax,[eax+edx]
  movq mm7,[eax]

  movq [ecx],mm0
  lea ecx,[ecx+edx]
  movq [ecx],mm1
  lea ecx,[ecx+edx]
  movq [ecx],mm2
  lea ecx,[ecx+edx]
  movq [ecx],mm3
  lea ecx,[ecx+edx]
  movq [ecx],mm4
  lea ecx,[ecx+edx]
  movq [ecx],mm5
  lea ecx,[ecx+edx]
  movq [ecx],mm6
  lea ecx,[ecx+edx]
  movq [ecx],mm7
		 
ret
