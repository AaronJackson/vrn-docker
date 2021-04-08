require 'torch'
require 'nn'
require 'nngraph'
require 'paths'

require 'image'
require 'xlua'
local utils = require 'utils'
local opts = require 'opts'(arg)

-- Load optional libraries

local FaceDetector = require 'facedetection_dlib'

torch.setheaptracking(true)
torch.setdefaulttensortype('torch.FloatTensor')
torch.setnumthreads(1)

local predictions = {}

local faceDetector = FaceDetector()

local model = torch.load(opts.model)
local modelZ
if opts.type == '3D-full' then
    modelZ = torch.load(opts.modelZ)

    modelZ:evaluate()
end

model:evaluate()

local img = image.load(opts.input)
-- Convert grayscale to pseudo-rgb
if img:size(1)==1 then
    img = torch.repeatTensor(img,3,1,1)
end

-- Detect faces, if needed
local detectedFaces, detectedFace

detectedFaces = faceDetector:detect(img)
if(#detectedFaces<1) then return end
center, scale =	utils.get_normalisation(detectedFaces[1])
detectedFace = detectedFaces[1]

img = utils.crop(img, center, scale, 256):view(1,3,256,256)

local output = model:forward(img)[4]:clone()
output:add(utils.flip(utils.shuffleLR(model:forward(utils.flip(img))[4])))
local preds_hm, preds_img = utils.getPreds(output, center, scale)

preds_hm = preds_hm:view(68,2):float()*4
-- depth prediction
if opts.type == '3D-full' then
    out = torch.zeros(68, 256, 256)
    for i=1,68 do
	        if preds_hm[i][1] > 0 then
    	    utils.drawGaussian(out[i], preds_hm[i], 2)
    	end
    end
    out = out:view(1,68,256,256)
    local inputZ = torch.cat(img:float(), out, 2)

    local depth_pred = modelZ:forward(inputZ):float():view(68,1) 
    preds_hm = torch.cat(preds_hm, depth_pred, 2)
end

if opts.save then
   local dest = opts.output
   if opts.outputFormat == 't7' then
	   torch.save(dest..'.t7', preds_img)
   elseif opts.outputFormat == 'txt' then
	   -- csv without header
	   local out = torch.DiskFile(dest, 'w')
	   for i=1,68 do
	       out:writeString(tostring(preds_img[{1,i,1}]) .. ',' .. tostring(preds_img[{1,i,2}]) .. '\n')
	   end
	   out:close()
   end
end


