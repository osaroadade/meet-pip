if (HTMLVideoElement.prototype.requestPictureInPicture) {
	HTMLVideoElement.prototype.requestPictureInPicture = function () {
		console.log("Native PiP blocked by MeetPIP extension.");
		return Promise.reject(new Error("PiP disabled by extension"));
	};
}
