//
//  Test1ViewController.m
//  SLPlayer_test
//
//  Created by lisd on 2017/12/4.
//  Copyright © 2017年 lisd. All rights reserved.
//

#import "Test1ViewController.h"
#import "SimpleAlignCell.h"
#import "SLPlayer.h"

@interface Test1ViewController ()<UITableViewDelegate ,UITableViewDataSource, SLPlayerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) SLPlayerView *playerView;
@end

@implementation Test1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor redColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self xy_registerTableView:self.tableView identifier:[SimpleAlignCell defaultReuseId]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SimpleAlignCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[SimpleAlignCell defaultReuseId]];
    __weak __typeof(self)weakSelf = self;
    __block NSIndexPath *weakIndexPath = indexPath;
    [cell setPlayBlock:^(UIButton *btn) {
        NSURL *videoURL = [NSURL URLWithString:@"https://image.52doushi.com/hiweixiu/1_20170401.mp4"];
        weakSelf.playerView = [[SLPlayerView alloc] init];
        [weakSelf.view addSubview:weakSelf.playerView];
        [weakSelf.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weakSelf.view).offset(20);
            make.left.right.equalTo(weakSelf.view);
            make.height.equalTo(weakSelf.playerView.mas_width).multipliedBy(9.0f/16.0f);
        }];
        SLPlayerControlView *controlView = [[SLPlayerControlView alloc] init];
        SLPlayerModel *playerModel = [[SLPlayerModel alloc] init];
        playerModel.videoURL         = videoURL;
        playerModel.scrollView       = weakSelf.tableView;
        playerModel.indexPath        = weakIndexPath;
        playerModel.fatherViewTag    = 100;
        [weakSelf.playerView playerControlView:controlView playerModel:playerModel];
        [weakSelf.playerView autoPlayTheVideo];
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 200;
}

-(void)xy_registerTableView:(UITableView*)tableView identifier:(NSString*)identifier{
    NSString *className = NSStringFromClass([SimpleAlignCell class]);
    UINib *nib = [UINib nibWithNibName:className bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:identifier];
}


- (SLPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [SLPlayerView sharedPlayerView];
        _playerView.playerLayerGravity = SLPlayerLayerGravityResize;
        _playerView.delegate = self;
        _playerView.cellPlayerOnCenter = NO;
    }
    return _playerView;
}

@end
