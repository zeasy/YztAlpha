//
//  ALPHADataRenderer.h
//  Alpha
//
//  Created by Dal Rupnik on 29/05/15.
//  Copyright (c) 2015 Unified Sense. All rights reserved.
//

#import "ALPHADataSource.h"
#import "ALPHAScreenModel.h"
#import "ALPHARequest.h"

/*!
 *  Data renderer protocol is made to support rendering of objects. Each data renderer must be able to render
 *  screen model, if correct type is provided. Data renderer should implement all scenarios below:
 *
 *  - If only screen model is provided to the renderer, it will render it as it is.
 *  - If object is provided to the data renderer, converter manager will be asked to convert data into
 *  screen model. If successful, new screen model should be rendered.
 *  - If request is provided, source will be asked to render scre
 */
@protocol ALPHADataRenderer <NSObject>

/*!
 *  Screen model
 */
@property (nonatomic, strong) ALPHAScreenModel* screenModel;

@optional

/*!
 *  Data model if available
 */
@property (nonatomic, strong) id<ALPHASerializableItem> object;

/*!
 *  A request to load when renderer is loaded (if object is not set)
 */
@property (nonatomic, copy) ALPHARequest *request;

/*!
 *  Data source, where data model is requested from
 */
@property (nonatomic, strong) id<ALPHADataSource> source;

@end
