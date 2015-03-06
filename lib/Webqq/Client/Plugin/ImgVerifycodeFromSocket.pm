package Webqq::Client::Plugin::ImgVerifycodeFromSocket;
use IO::Socket::INET;
use Webqq::Client::Util qw(console);
use HTTP::Date;
use IO::Handle;

use File::Basename;
sub call{
    my $client = shift;
    my($img_verifycode_file) =@_;
    my $img_path = basename($img_verifycode_file);
    my $internet_host = '127.0.0.1';
    my $msg  = "主人，登录需要验证码，请点击以下链接输入验证码: http://$internet_host:1987/post_img_code ";
    console $msg;
    my $s = IO::Socket::INET->new(
        LocalPort => 1987,
        Proto     => 'tcp' ,
        Reuse => 1,
        Blocking => 1,
        Listen    => SOMAXCONN,
    ) or die $!;
    my $html= <<"HTML";
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
    <form action="http://$internet_host:1987/img_code" method="get">
        <div><img src="http://$internet_host:1987/$img_path"></img></div>
        <nobr>验证码：</nobr>
        <input type="text" maxlength="4" size="4" name="code"></input>
        <input type="submit"></input>
    </form>
</body>
</html>
HTML
    
    while(my $c = $s->accept()){
        my $uri;
        $c->autoflush(1);
        while(<$c>){
            last if /^\s+$/;
            (undef,$uri,undef)= split /\s+/,$_ if $_ =~/^GET/;
        }        
        if($uri eq "/$img_path"){
            my $data;
            open my $img,$img_verifycode_file or die $!;
            while((read $img,my $buf,4096)!=0){
                $data .= $buf;
            }
            close $img;
            my $len = length($data);
            print $c
                "HTTP/1.1 200 OK\r\n" .
                "Date: " . time2str() . "\r\n" .
                "Content-Type: image/jpeg\r\n" .
                "Content-Length: $len\r\n" .
                "\r\n" .
                $data;
        }
        elsif($uri eq '/post_img_code'){
            my $len = length($html);
            print $c
                "HTTP/1.1 200 OK\r\n" .
                "Date: " . time2str() . "\r\n" .
                "Content-Type: text/html;charset=utf-8\r\n" .
                "Content-Length: $len\r\n" ;
            print $c "\r\n";
            print $c $html;
        }   
        elsif($uri =~ /\/img_code\?code=(.{4})/){
            my $code = $1;
            my $data = "验证码已提交" ;
            my $len = length($data);
            print $c 
                "HTTP/1.1 200 OK\r\n" .
                "Date: " . time2str() . "\r\n" .
                "Content-Type: text/html;charset=utf-8\r\n" .
                "Content-Length: $len\r\n" . 
                "\r\n" . 
                $data;
            return $code if defined $code and length($code)==4;
        }
        else{
            print $c
                "HTTP/1.1 404 Not Found\r\n" .
                "Date: " . time2str() . "\r\n" .
                "Content-Length: 0\r\n";
        }
    }
}

1;
