﻿import com.transfusionmedia.utils.*;
import com.transfusionmedia.mvc.*;
import com.transfusionmedia.Player.*;
import mx.transitions.Tween;
import mx.transitions.easing.*;

/**
 * View class for the media player
 * 
 * @author  	    Warren Benedetto <warren@transfusionmedia.com>
 */

class com.transfusionmedia.Player.PlayerView extends AbstractView {
	
	/**
	 * The width of the progress bar. Used to calculate offset to jump media
	 * when progress bar is clicked
	 */
	private var PROGRESS_BAR_WIDTH:Number		= 0;
	
	/**
	 * The number of seconds to wait before auto-hiding player control layer
	 */
	public var AUTO_HIDE_TIMEOUT:Number			= 2;
	
	/**
	 * Holds the interval for the auto-hide timeout
	 */
	public var autoHideInterval					= 0;
	
	/**
	 * Holds the interval for tracking whether the mouse is moving
	 */
	public var mouseMoveInterval				= 0;
	
	/**
	 * True when mouse is moving
	 */
	public var isMouseMoving					= false;
	
	/**
	 * Constructor
	 * 
	 * @param	model				The model which the view will render
	 * @param	controller			The controller that receives events from the view and updates the model
	 */
	public function PlayerView(model:Player, controller:Controller) {
		
		super(model, controller);
		Trace.header('PlayerView constructed');
		
		var model:Player							 = Player(this.getModel());
		model.setProgressBarWidth(this.PROGRESS_BAR_WIDTH);
		
	}
	
	/**
	* Returns the default controller for this view.
	*/
	public function defaultController (model:Player):Controller {
		
		Trace.message('Getting default controller');
		return new PlayerController(model);
	}
	
	/**
	 * Initialize view
	 */
	public function init():Void {
		
		Trace.header('Initializing PlayerView');
		this.initPlaceholder();
		this.initTitle();
		this.initProgressBar();
		this.initPlayerControls();
		this.initVideoOptions();
	}
	
	/**
	 * Receives update event from model when it changes
	 * 
	 * @param	model					The model sending the update
	 * @param	infoObj					Generic info object
	 */
	public function update(model:Player, infoObj:Object) {
		
		Trace.message('PlayerView update from Player model');
		
		if (model.isControlLayerSliding() == true) {		
			this.moveControlLayer();
		} else if (infoObj.newMediaState != undefined) {
			this.togglePlayButton(infoObj.newMediaState);
		} else if (infoObj.newVolume != undefined) {
			this.toggleMuteButton(infoObj.newVolume);
		} else if (infoObj.isFullScreen != undefined) {
			this.toggleFullScreen(infoObj.isFullScreen);
		} else if (infoObj.resizeVideo == true) {
			this.resizeVideoPlayer(infoObj.width,infoObj.height);
		}
	}
	
	/**
	 * Loads placeholder image
	 */
	private function initPlaceholder():Void {
		
		var model:Player					= Player(this.getModel());
		
		/* Scale image to Stage */
		var initObj:Object					= new Object();
		initObj.width						= Stage.width;
		initObj.height						= Stage.height;

		var placeholder:MovieClip			= model.getPlaceholder();

		/* Load placeholder image */
		this.loadImage(placeholder.url, placeholder, initObj);
	}
	
	/**
	 * Loads video title, author name, and author image into player.
	 * Only used when player is embedded.
	 */
	private function initTitle():Void {
		
		var model:Player					= Player(this.getModel());
		
		if (model.isLocal() == false) {
			
			var titleHolder:MovieClip			= model.getTitleHolder();
			
			/* Load title and author name */
			titleHolder.title.text				= model.oembed.title;
			titleHolder.author.text				= 'Created by: ' + model.oembed.authorName;
			
			/* Load author image */
			var initObj:Object					= new Object();
			initObj.width						= 80;
			initObj.height						= 80;
			this.loadImage(model.oembed.authorImageURL, titleHolder.imageHolderMC, initObj);
			
			var titleHolderTween:Tween 		= new Tween (titleHolder,"_y",Strong.easeOut,-105,10,.6,true);
		}
	}
	
	/**
	 * Initializes the progess bar: video progress, buffering, and jump to cue point on click
	 */
	private function initProgressBar():Void {
		
		Trace.message('Initializing progress bar');
		
		var controller:PlayerController		= PlayerController(this.getController());
		var model							= Player(this.getModel());
		var playerControlBar:MovieClip		= model.getPlayerControlBar();
		var progressBar:MovieClip			= playerControlBar.playerControls.progressBarMC.progressBar;
		var progressBarBG:MovieClip			= playerControlBar.playerControls.progressBarMC.progressBarBG;
		var bufferingBar:MovieClip			= playerControlBar.playerControls.progressBarMC.bufferingBar;
		
		/* Start progress and buffering bars at zero width */
		progressBar._width					= 0;
		bufferingBar._width					= 0;
		
		var increment:Number				= model.getProgressBarWidth() / 100;
		
		/* Check how much of the video is loaded */
		bufferingBar.onEnterFrame 			= function() {
			
			/* Fill buffering bar in proportion to the percent loaded */
			var percentLoaded:Number		= model.getPercentLoaded();
			this._width						= percentLoaded * increment;
			
			/* Once video is fully loaded, delete onEnterFrame */
			if (percentLoaded == 100) {
				delete this.onEnterFrame;
			}
		}
		
		/* Check how much of the video has played */
		progressBar.onEnterFrame 			= function() {
			
			/* Fill progress bar in proportion to the percent completed */
			var percentCompleted:Number		= model.getPercentCompleted();
			this._width						= percentCompleted * increment;
		}
		
		/* Jump media to cue point when buffering bar is clicked. Buffering bar is used
		 * to prevent users from jumping beyond the point where the video is loaded */
		bufferingBar.onRelease				= function() {
			if (progressBarBG._xmouse <= this.width){
				controller.jumpToCuePoint(progressBarBG._xmouse);
			}
		}
	}
	
	/**
	 * Initializes the video options panel (share, embed, etc)
	 */
	private function initVideoOptions():Void {
		
		var controller:PlayerController		= PlayerController(this.getController());
		var model:Player					= Player(this.getModel());
		var videoOptions:MovieClip			= model.getVideoOptions();
		var videoOptionsOverlay:MovieClip	= model.getVideoOptionsOverlay();
		
		/* Embed */
		videoOptions.embedButton.onRelease	= function() {
			
			Trace.header('Embed button clicked');
			controller.showEmbedInterface();
		}
		/* Share */
		videoOptions.shareButton.onRelease	= function() {
			
			Trace.header('Share button clicked');
			controller.showShareInterface();
		}
		
		videoOptionsOverlay.content.copyButton.onPress = function() {
				
			Trace.header('Copy to clipboard');
			Trace.message(videoOptionsOverlay.content.code.text);
			
			System.setClipboard(videoOptionsOverlay.content.code.text);
			videoOptionsOverlay.content.copyButton.copyButtonText.text = 'Copied';
		}
		
		videoOptionsOverlay.content.closeButton.onPress = function() {
			videoOptionsOverlay.gotoAndPlay('close');
		}
	}

	/**
	 * Initializes player controls
	 */
	private function initPlayerControls():Void {
		
		Trace.message('Initializing player controls');
		
		var controller:PlayerController		= PlayerController(this.getController());
		var model:Player					= Player(this.getModel());
		var playerControlBar:MovieClip		= model.getPlayerControlBar();
		
		/* Set default control layer state */
		model.setControlLayerState('in');
		
		/* Hide mute overlay and Pause button */
		playerControlBar.playerControls.pauseButton._visible 					= false;
		playerControlBar.playerControls.secondaryControls.muteOverlay._visible 	= false;
		
		/* Set interval to check if mouse is still moving after 2 seconds */
		this.mouseMoveInterval				= setInterval(this,'monitorMouseMove', 2000);

		var owner							= this;
		
		/* Monitor control bar location to hide it as needed */
		playerControlBar.onEnterFrame 			= function() {

			/* If the mouse is off the stage, and the control layer is showing, hide it */
			if (model.getControlLayerState() == 'in' && owner.isMouseOnStage() == false && model.isStopped() == false) {
				controller.hideControlLayer();
			} 
			
			/* Update media timer */
			this.playerControls.progressBarMC.videoTimerMC.videoTimer.text = model.getTimer();
			
			if (Stage.displayState== 'normal' && playerControlBar.playerControls.secondaryControls._visible == false) {
				playerControlBar.playerControls.secondaryControls._visible	= true;
			}
		}
		
		/* If the mouse moves, and the control layer is not already on stage, show it */
		_root.onMouseMove					= function() {
			
			if (model.getControlLayerState() == 'out') {
				controller.showControlLayer();
			} 
			owner.isMouseMoving				= true;
		}
		
		/* Play */
		playerControlBar.playerControls.playButton.onRelease	= function() {
			
			Trace.header('Play button clicked');
			controller.togglePlay();
		}
		/* Pause */
		playerControlBar.playerControls.pauseButton.onRelease	= function() {
			
			Trace.header('Pause button clicked');
			controller.togglePlay();
		}
		/* Mute */
		playerControlBar.playerControls.secondaryControls.muteButton.onRelease	= function() {
			
			Trace.header('Mute button clicked');
			controller.toggleMute();
		}
		/* Aptana.tv logo */
		playerControlBar.playerControls.secondaryControls.aptanaLogo.onRelease	= function() {
			
			Trace.header('Aptana.tv logo clicked');
			
			/* TODO: Change hard-coded url to use url from XML feed */
			getURL(model.getLogoClickURL(),'_blank');
		}
		/* Full screen */
		playerControlBar.playerControls.secondaryControls.fullScreenButton.onRelease	= function() {
			
			Trace.header('Full screen button clicked');
			controller.toggleFullScreen();
		}
		/* Timer */
		playerControlBar.playerControls.progressBarMC.videoTimerMC.onRelease	= function() {
			
			Trace.header('Timer clicked');
			controller.toggleTimer();
		}
	}
	
	/**
	 * Monitors the mouse movement to see if the mouse is still moving 2 seconds after it last
	 * moved. If it isn't, and the control layer is showing, hide it.
	 */
	public function monitorMouseMove():Void {

		var controller:PlayerController		= PlayerController(this.getController());
		var model:Player					= Player(this.getModel());
		
		/* If the control layer is showing, the mouse isn't moving, and the video is playing or paused, hide the control layer */
		if (model.getControlLayerState() == 'in' && this.isMouseMoving == false && model.isStopped() == false) {
			controller.hideControlLayer();
		} 
		/* If the control layer is not showing, and the video is stopped, show the control layer */
		else if (model.getControlLayerState() == 'out' && model.isStopped() == true) {
			controller.showControlLayer();
		}
		this.isMouseMoving 					= false;
	}

	/**
	 * Moves control layer on and off the screen
	 */
	public function moveControlLayer():Void {
		
		Trace.header('Moving control layer');
		
		var model								= Player(this.getModel());
		var playerControlBar:MovieClip			= model.getPlayerControlBar();
		var videoOptions:MovieClip				= model.getVideoOptions();

		Trace.message('Control layer state is ' + model.getControlLayerState());

		/* If control layer state is 'in', slide controls off screen */
		if (model.getControlLayerState() == 'in') {
			Trace.message('Slide in');
			var playerControlBarTween:Tween 	= new Tween (playerControlBar.playerControls,"_y",Strong.easeOut,80,0,.6,true);
			var videoOptionsTween:Tween 		= new Tween (videoOptions,"_x",Strong.easeOut,600,530,.6,true);
		} 
		/* If control layer state is 'out' slide controls on screen */
		else {
			Trace.message('Slide out');
			var playerControlBarTween:Tween 	= new Tween (playerControlBar.playerControls,"_y",Strong.easeOut,0,80,.6,true);	
			var videoOptionsTween:Tween 		= new Tween (videoOptions,"_x",Strong.easeOut,530,600,.6,true);	
		}
		
		var owner								= this;
		
		/* When the control layer is done moving, update the moodel */
		playerControlBarTween.onMotionFinished	= function() {
			Trace.message('Slide complete');
			model.setControlLayerSliding(false);
		}
	}
	
	/**
	 * Toggles play button between Play and Pause
	 * 
	 * @param	mediaState		The media state: play, pause, or stop
	 */
	public function togglePlayButton(mediaState:String):Void {
		
		Trace.header('Toggling play button');
		
		var model									= Player(this.getModel());
		var playerControlBar:MovieClip				= model.getPlayerControlBar();
		var playerControls:MovieClip				= playerControlBar.playerControls;
		var titleHolder:MovieClip					= model.getTitleHolder();
		
		/* If the media is playing, show the Pause button and hide the Play button */
		if (mediaState == 'play') {
			playerControlBar.playerControls.playButton._visible 		= false;
			playerControlBar.playerControls.pauseButton._visible 		= true;
			
			/* Once Play is clicked once, the title fades out and never comes back */
			if (model.titleVisible == true){
				var titleHolderTween:Tween 			= new Tween (titleHolder, "_alpha", Strong.easeOut, 100, 0, .6, true);
				model.titleVisible 					= false;
			}
		} 
		/* Otherwise, show the Play button and hide the Pause button */
		else {
			playerControlBar.playerControls.playButton._visible 		= true
			playerControlBar.playerControls.pauseButton._visible 		= false;
		}
	}
	
	/**
	 * Toggles the mute button overlay
	 * 
	 * @param	newVolume		The new volume (0 or 100)
	 */
	public function toggleMuteButton(newVolume:Number):Void {
		
		Trace.header('Toggling mute button');
		
		var model									= Player(this.getModel());
		var playerControlBar:MovieClip				= model.getPlayerControlBar();
		
		/* If the volume is zero, it's muted. Show the mute button overlay */
		if (newVolume == 0) {
			playerControlBar.playerControls.secondaryControls.muteOverlay._visible 	= true;
		} 
		/* Otherwise, hide the mute button overlay */
		else {
			playerControlBar.playerControls.secondaryControls.muteOverlay._visible 	= false;
		}
	}
	
	/**
	 * Toggles the player between normal and full screen mode
	 * 
	 * @param	isFullScreen		True if the player should be full screen
	 */
	public function toggleFullScreen(isFullScreen:Boolean):Void {
		
		Trace.header('Toggling full screen. isFullScreen is set to ' + isFullScreen);
		
		var model									= Player(this.getModel());
		var playerControlBar:MovieClip				= model.getPlayerControlBar();
		
		/* Go full screen */
		if (isFullScreen == true) {
			playerControlBar.playerControls.secondaryControls._visible = false;
			Stage.displayState						= 'fullScreen';
		} 
		/* Return to normal screen mode */
		else {
			playerControlBar.playerControls.secondaryControls._visible = true;
			Stage.displayState						= 'normal';
		}
	}
	
	/**
	 * @return True if the user's mouse is on the stage
	 */
	public function isMouseOnStage():Boolean {
		
		var padding:Number							= 0;
		return (_root._xmouse > padding && _root._xmouse < (Stage.width - padding) && _root._ymouse > padding && _root._ymouse < (Stage.height - padding))
	}
	
	/**
	 * Loads image into given movieclip
	 * 
	 * @param	imageURL
	 */
	private function loadImage(imageURL:String, imageHolderMC:MovieClip, initObj:Object):Void {
		
		Trace.header('Loading image');
		Trace.message('Image URL: ' + imageURL);
		Trace.message('Image holder: ' + imageHolderMC);
		
		var owner								= this;
		var imageLoader:MovieClipLoader 		= new MovieClipLoader();

		/* Creates listener to detect when image is loaded */
		var imageListener:Object				= new Object();
		imageLoader.addListener(imageListener);
		
		/* Loads image */
		imageLoader.loadClip(imageURL, imageHolderMC);
		
		imageListener.onLoadInit = function() {
			
			Trace.message('Image loaded');
			
			if (initObj != undefined){
				imageHolderMC._width 			= initObj.width;
				imageHolderMC._height 			= initObj.height;
			}

		}
		imageListener.onLoadError = function(imageHolderMC:MovieClip, errorCode:String, httpStatus:Number) {
			
			Trace.header('Error loading image');
			Trace.message('Image URL: ' + imageURL);
			Trace.message('Error code: ' + errorCode);
			Trace.message('HTTP status: ' + httpStatus);
		}
	}
	
	/**
	 * Resizes the player for oversized videos to fit within the Stage
	 * 
	 * @param	width		The width of the video
	 * @param	height		The height of the video
	 */
	private function resizeVideoPlayer(width:Number, height:Number):Void {
		
		Trace.header('Resizing video player');
		Trace.message('width: ' + width);
		Trace.message('height: ' + height);
		Trace.message('proportion: ' + height/width);
		
		var model:Player						= Player(this.getModel());
		var videoPlayer:Object					= model.video;
		
		/* Scale video to fill full width (letterboxing on top/bottom if needed) */
		videoPlayer._width						= width * (Stage.width/width);
		videoPlayer._height						= height * (Stage.width / width);
		
		/* If scaled video height exceeds Stage height, resize to fill full height
		 * instead (letterbox video on sides) */
		if (videoPlayer._height > Stage.height) {
			videoPlayer._width					= width * (Stage.height/height);
			videoPlayer._height					= height * (Stage.height / height);
		}
		videoPlayer._x							= (Stage.width - videoPlayer._width) / 2;
		videoPlayer._y							= (Stage.height - videoPlayer._height) / 2;
	}
}