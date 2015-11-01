import UIKit

//The bubble on the right-side of the card number that changes
//when enough numbers have been entered in the number field
class AcceptOnCreditCardNumBrandPop: UIView
{
    //-----------------------------------------------------------------------------------------------------
    //Properties
    //-----------------------------------------------------------------------------------------------------
    //The view that is actually animated and contains two image views (for double buffering during animations)
    var popView = UIView()
        let imageA = UIImageView()
        let imageB = UIImageView() //ontop of A
    lazy var activeImageBuffer: UIImageView? = self.imageA
    
    //A queue used for both loading brandImages if needed and then
    //animating them without contention
    let animationQueue = NSOperationQueue()
    
    //Cached brand images and a listing of image names
    var brandImages: [String:UIImage] = [:]
    let brandNameToImageName: [String:String] = [
        "amex": "amex",
        "visa": "visa",
        "discover": "discover",
        "master_card": "master_card",
        "unknown":"unknown"
    ]
    
    //-----------------------------------------------------------------------------------------------------
    //Constructors, Initializers, and UIView lifecycle
    //-----------------------------------------------------------------------------------------------------
    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        defaultInit()
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    func defaultInit() {
        //Our animation queue needs to block
        animationQueue.maxConcurrentOperationCount = 1
        
        //Add a pop-view for when the images are swapped out
        self.addSubview(popView)
        popView.layer.masksToBounds = true
        
        //Add two image views (double buffered)
        for e in [imageA, imageB] {
            popView.addSubview(e)
            e.contentMode = UIViewContentMode.ScaleAspectFill
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Make it a circle
        self.popView.layer.cornerRadius = self.popView.bounds.size.height/2
    }
    
    var constraintsWereUpdated = false
    override func updateConstraints() {
        super.updateConstraints()
        
        //Only run custom constraints once
        if (constraintsWereUpdated) { return }
        constraintsWereUpdated = true
        
        //Pop-view should be centered & square 63% the size
        popView.snp_makeConstraints { make in
            make.width.equalTo(self.snp_width).multipliedBy(0.63)
            make.height.equalTo(popView.snp_width)
            make.center.equalTo(self.snp_center)
            return
        }
        
        //Set-up our double buffered image views inside the pop-views
        for e in [imageA, imageB] {
            e.snp_makeConstraints { make in
                make.margins.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
                return
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------------------
    //Animation Helpers
    //-----------------------------------------------------------------------------------------------------
    //Accepts visa, master_card, unknown, etc. Switches to the image
    //for that card by animating out the current card and animating
    //in a new card
    func switchToBrandWithName(name: String) {
        animationQueue.addOperationWithBlock { [weak self] () -> Void in
            //Do we have the image cached?
            var image = self?.brandImages[name]
            
            //Not cached? Load it synchronously
            if (image == nil) {
                if let imageName = self?.brandNameToImageName[name] {
                    image = AcceptOnBundle.UIImageNamed(imageName)
                    self?.brandImages[imageName] = image
                }
            }
            
            //Animate to the other brand image
            if let image = image {
                self?.animateFromCurrentBrandImageToOtherBrandImageWithImage(image)
            } else {
                puts("Warning: couldn't switchToBrandWithName for brand: \(name) because it didn't exist as an image")
            }
        }
    }
    
    //Handles animating between the two image buffers
    func animateFromCurrentBrandImageToOtherBrandImageWithImage(image: UIImage) {
        //Get the 'other' buffer.  If we're on A, return B. and vice-versa
        let alternativeImageBuffer: UIImageView? = activeImageBuffer == imageA ? imageB : imageA
        
        //Lock this thread up until animations complete
        let dispatchLock = dispatch_semaphore_create(0)
        
        //Set the image of the 'other' buffer
        dispatch_sync(dispatch_get_main_queue()) { [weak self] () -> Void in
            alternativeImageBuffer?.alpha = 0
            alternativeImageBuffer?.image = image
            
            //Animate the pop out
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self?.popView.layer.transform = CATransform3DMakeScale(0.0001, 0.0001, 1)
            }, completion: { res in
                //Animate the pop in with the alternative image
                alternativeImageBuffer?.alpha = 1
                self?.activeImageBuffer?.alpha = 0
                UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    self?.popView.layer.transform = CATransform3DIdentity
                }, completion: { res in
                    //Signal that we are done
                    dispatch_semaphore_signal(dispatchLock)
                })
            })
        }
        
        //Lock this NSOperation until we've completed our animations, or 5 seconds have passed,
        //as animation sub-system has no guarantees on actually completing our request
        let maxWaitInSecs = 5
        dispatch_semaphore_wait(dispatchLock, dispatch_time(DISPATCH_TIME_NOW, Int64(maxWaitInSecs)*Int64(NSEC_PER_SEC)))
        
        //Swap buffers out
        activeImageBuffer = alternativeImageBuffer
    }
}