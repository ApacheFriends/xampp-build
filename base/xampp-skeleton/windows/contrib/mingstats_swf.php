<?php

    // Copyright (C) 2005 Kai Seidler, oswald@apachefriends.org
    //
    // This program is free software; you can redistribute it and/or modify
    // it under the terms of the GNU General Public License as published by
    // the Free Software Foundation; either version 2 of the License, or
    // (at your option) any later version.
    //
    // This program is distributed in the hope that it will be useful,
    // but WITHOUT ANY WARRANTY; without even the implied warranty of
    // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    // GNU General Public License for more details.
    //
    // You should have received a copy of the GNU General Public License
    // along with this program; if not, write to the Free Software
    // Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
    //

    $values["A"]=rand(20,230);
    $values["B"]=rand(20,230);
    $values["C"]=rand(20,230);
    $values["D"]=rand(20,230);
    $values["E"]=rand(20,230);
    $values["F"]=rand(20,270);
    $values["G"]=rand(20,270);
    $values["H"]=rand(20,270);

    $max=270;

    $width=540;
    $height=320;

    $m = new SWFMovie();
    $m->setDimension($width, $height);
    $m->setBackground(251, 121, 34);
    $m->setRate(30.0);

    $font = new SWFFont("BabelSans-B.fdb");

    $g = new SWFGradient();
    $g->addEntry(0.0, 0, 0, 0);
    $g->addEntry(1.0, 0xff, 0xff, 0xff);
  
    function box($w,$h)
    {
	global $g;

        $s = new SWFShape();
	$f=$s->addFill($g, SWFFILL_LINEAR_GRADIENT);
	$f->scaleTo(0.05);
        $s->setRightFill($f);
        //$s->setRightFill($s->addFill(255,255,255));
        $s->movePenTo(0, 0);
        $s->drawLineTo($w, 0);
        $s->drawLineTo($w, -$h);
        $s->drawLineTo(0, -$h);
        $s->drawLineTo(0, 0);
	return $s;
    }

    function text($string)
    {
	global $font;

	$t = new SWFText();
	$t->setFont($font);
	$t->setColor(255, 255, 255);
	$t->setHeight(20);
	$t->addString($string);

	return $t;
    }

    $t=$m->add(text("Balkendiagramm mit PHP und Ming"));
    $t->moveTo(30,40);

    $i=0;
    reset($values);
    while(list($key,$value) = each($values))
    {
        $text[$i]=$m->add(text($key));
	$text[$i]->moveTo(50+$i*60,50);
	$box[$i]=$m->add(box(50,1));
	$box[$i]->moveTo(30+$i*60,$height-20);
	$box[$i]->setName("box".$i);
        $i++;
    }

    for($f=0;$f<=$max;$f+=5) 
    {
        $i=0;
	reset($values);
        while(list($key,$value) = each($values))
        {
	    $h=$value;
	    if($h>$f)
	    {
            	$box[$i]->scaleTo(1,$f);
		$text[$i]->moveTo(50+$i*60,$height-$f-25);
            }
	    $i++;
        }
        $m->nextFrame();
    }

    $m->add(new SWFAction("stop();"));
    $m->nextFrame();

    header('Content-type: application/x-shockwave-flash');
    $m->output();
?>
